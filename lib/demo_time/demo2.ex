defmodule DemoTime.Demo2 do
  def create_in_memory() do
    if :ets.info(:table1) == :undefined do
      :ets.new(:table1, [:bag, :public, :named_table])
    end

    :ok
  end

  def set_in_memory(key, value), do: :ets.insert(:table1, {key, value})
  def get_in_memory(key), do: :ets.lookup(:table1, key)

  def create_file(path), do: :dets.open_file(:table2, [{:file, to_charlist(path)}])
  def close_file(), do: :dets.close(:table2)
  def set_file(key, value), do: :dets.insert(:table2, {key, value})
  def get_file(key), do: :dets.lookup(:table2, key)

  def create_distributed() do
    node_list = Node.list() ++ [Node.self()]
    :mnesia.create_schema(node_list)
    # Starts mnesia on all nodes
    :rpc.multicall(node_list, :mnesia, :start, [])
    :mnesia.create_table(:db, attributes: [:key, :value], disc_copies: node_list)
    :ok
  end

  def set_distributed(key, value) do
    :mnesia.transaction(fn -> :mnesia.write({:db, key, value}) end)
  end

  def get_distributed(key) do
    {:atomic, [{_, k, v}]} = :mnesia.transaction(fn -> :mnesia.read({:db, key}) end)
    [{k, v}]
  end
end
