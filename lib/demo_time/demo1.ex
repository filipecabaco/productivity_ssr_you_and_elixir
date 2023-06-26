defmodule DemoTime.Demo1 do
  require Logger
  use GenServer

  def broadcast(topic, message), do: GenServer.cast(:"broadcast_#{topic}", {:broadcast, message})

  def start_link(topic: topic), do: GenServer.start_link(__MODULE__, %{topic: topic}, name: :"broadcast_#{topic}")

  @impl true
  def init(state), do: {:ok, state, {:continue, :set_monitors}}

  @impl true
  def handle_continue(:set_monitors, %{topic: topic} = state) do
    connect_nodes()
    # :pg it's an OTP module
    :pg.join(topic, self())
    Logger.info("Connected to message_queue process group")
    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast, content}, %{topic: topic} = state) do
    Enum.each(:pg.get_members(topic), &send(&1, {:message, content}))
    {:noreply, state}
  end

  @impl true
  def handle_info({:message, content}, state) do
    Logger.info("Received: #{inspect(content)}")
    {:noreply, state}
  end

  defp connect_nodes() do
    {:ok, names} = :net_adm.names()

    names
    |> Enum.map(&elem(&1, 0))
    |> Enum.map(&List.to_string/1)
    |> Enum.map(&:"#{&1}@127.0.0.1")
    |> Enum.reject(&(&1 == Node.self()))
    |> Enum.map(&Node.connect/1)
  end
end
