defmodule DemoTime.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  @topics [:message_queue]

  use Application
  require Logger
  @impl true
  def start(_type, _args) do
    children =
      [
        DemoTimeWeb.Telemetry,
        DemoTime.Repo,
        {Phoenix.PubSub, name: DemoTime.PubSub},
        DemoTimeWeb.Presence,
        DemoTimeWeb.Monitor,
        DemoTimeWeb.Endpoint,
        {DemoTime.Demo4, %{topic: :events, mod: DemoTime.Worker, fun: :consume}},
        %{id: :pg, start: {:pg, :start_link, []}}
      ] ++ Enum.map(@topics, &{DemoTime.Demo1, topic: &1}) ++ live3_sauce()

    opts = [strategy: :one_for_one, name: DemoTime.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DemoTimeWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  def live3_sauce() do
    {:ok, emotion_model_info} = Bumblebee.load_model({:hf, "finiteautomata/bertweet-base-sentiment-analysis"})
    {:ok, emotion_tokenizer} = Bumblebee.load_tokenizer({:hf, "vinai/bertweet-base"})

    {:ok, labeller_model_info} = Bumblebee.load_model({:hf, "facebook/bart-large-mnli"})
    {:ok, labeller_tokenizer} = Bumblebee.load_tokenizer({:hf, "facebook/bart-large-mnli"})

    compile = [batch_size: 2, sequence_length: 200]
    defn_options = [compiler: EXLA]

    emotion_serving =
      Bumblebee.Text.text_classification(
        emotion_model_info,
        emotion_tokenizer,
        compile: compile,
        defn_options: defn_options
      )

    labeller_serving =
      Bumblebee.Text.zero_shot_classification(
        labeller_model_info,
        labeller_tokenizer,
        ~w(technology culture travel shopping politics finance sports food),
        compile: compile,
        defn_options: defn_options
      )

    [
      {Nx.Serving, serving: emotion_serving, name: EmotionServing, batch_timeout: 100},
      {Nx.Serving, serving: labeller_serving, name: LabellerServing, batch_timeout: 100}
    ]
  end
end
