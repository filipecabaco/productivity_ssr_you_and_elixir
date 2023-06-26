defmodule DemoTimeWeb.Monitor do
  use GenServer
  require Logger
  def start_link(_), do: GenServer.start_link(__MODULE__, MapSet.new(), name: __MODULE__)
  def init(state), do: {:ok, state, {:continue, :set_tracker}}

  def handle_continue(:set_tracker, state) do
    Process.send_after(self(), :check, 1000)
    {:noreply, state}
  end

  def monitor(pid, id), do: GenServer.cast(__MODULE__, {:monitor, pid, id})

  def handle_cast({:monitor, pid, id}, state), do: {:noreply, MapSet.put(state, {pid, id})}

  def handle_info(:check, state) do
    state =
      Enum.reduce(state, state, fn {pid, id}, state ->
        case Process.alive?(pid) do
          true ->
            state

          false ->
            DemoTimeWeb.Endpoint.broadcast("presence", "presence_diff", %{leaves: [id]})
            MapSet.delete(state, {pid, id})
        end
      end)

    Process.send_after(self(), :check, 200)

    {:noreply, state}
  end
end
