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
        DemoTimeWeb.Endpoint,
        {DemoTime.Demo4, %{topic: :events, mod: DemoTime.Worker, fun: :consume}},
        %{id: :pg, start: {:pg, :start_link, []}}
      ] ++ Enum.map(@topics, &{DemoTime.Demo1, topic: &1})

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
end
