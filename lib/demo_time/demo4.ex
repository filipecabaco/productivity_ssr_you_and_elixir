defmodule DemoTime.Demo4 do
  use GenServer
  require Logger

  def broadcast(topic, message), do: GenServer.cast(:"broadcast_#{topic}", {:broadcast, message})
  def fetch_since(topic, ts), do: GenServer.call(:"broadcast_#{topic}", {:fetch_since, ts})
  def replay_since(topic, ts), do: GenServer.cast(:"broadcast_#{topic}", {:replay_since, ts})

  ## SETUP GENSERVER
  def start_link(%{topic: topic, mod: mod, fun: fun}),
    do:
      GenServer.start_link(__MODULE__, %{topic: topic, mod: mod, fun: fun},
        name: :"broadcast_#{topic}"
      )

  @impl true
  def init(state), do: {:ok, state, {:continue, :connect_to_nodes}}

  @impl true
  def handle_continue(:connect_to_nodes, state) do
    connect_nodes()
    Logger.info("Connected to nodes")
    {:noreply, state, {:continue, :connect_to_topic}}
  end

  def handle_continue(:connect_to_topic, %{topic: topic} = state) do
    :pg.join(topic, self())
    Logger.info("Connected to topic")
    {:noreply, state, {:continue, :connect_to_db}}
  end

  def handle_continue(:connect_to_db, %{topic: topic} = state) do
    node_list = node_list()
    :mnesia.create_schema(node_list)
    :mnesia.start()

    opts = [attributes: [:ts, :content], disc_copies: node_list, type: :ordered_set]

    case :mnesia.create_table(topic, opts) do
      {:aborted, _} ->
        :pg.get_members(topic)
        |> Enum.reject(&(&1 in :pg.get_local_members(:events)))
        |> Enum.each(&send(&1, {:connect_node, Node.self()}))

      _ ->
        :mnesia.wait_for_tables([:events], 5000)
        Logger.info("Connected to db")
        :ok
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:broadcast, content}, %{topic: topic} = state) do
    {:atomic, :ok} =
      :mnesia.transaction(fn ->
        ts = DateTime.utc_now() |> DateTime.to_unix(:microsecond)
        :mnesia.write({topic, ts, content})
      end)

    Enum.each(:pg.get_members(topic), &send(&1, {:message, content}))
    {:noreply, state}
  end

  def handle_cast({:replay_since, ts}, %{topic: topic, mod: mod, fun: fun} = state) do
    res = fetch_from_topic_since_ts(topic, ts)

    Enum.each(res, fn [_, _, content] -> apply(mod, fun, [content]) end)
    {:noreply, state}
  end

  @impl true
  def handle_call({:fetch_since, ts}, _, %{topic: topic} = state) do
    res = fetch_from_topic_since_ts(topic, ts)
    {:reply, res, state}
  end

  @impl true
  def handle_info({:message, content}, %{mod: mod, fun: fun} = state) do
    apply(mod, fun, [content])
    {:noreply, state}
  end

  @impl true
  def handle_info({:connect_node, node}, %{topic: topic} = state) do
    nodes = node_list()
    :mnesia.change_config(:extra_db_nodes, nodes)
    :mnesia.change_table_copy_type(topic, nodes, :disc_copies)
    :mnesia.add_table_copy(topic, node, :disc_copies)
    :mnesia.wait_for_tables([topic], 5000)

    {:noreply, state}
  end

  @ts_match {:"$1", :"$2", :"$3"}
  defp fetch_from_topic_since_ts(topic, ts) do
    ts_guard = [{:>, :"$2", ts}]

    {:atomic, res} =
      :mnesia.transaction(fn ->
        :mnesia.select(topic, [{@ts_match, ts_guard, [:"$$"]}])
      end)

    res
  end

  defp node_list(), do: Node.list() ++ [Node.self()]

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

defmodule DemoTime.Worker do
  require Logger
  def consume(%{event: %{important: true}}), do: Logger.warn("IMPORTANT")
  def consume(%{event: %{important: false}}), do: Logger.info("Information")
end
