defmodule DemoTime.Demo2 do
  def create_in_memory() do
    if :ets.info(:in_memory) == :undefined do
      :ets.new(:in_memory, [:bag, :public, :named_table])
    end

    :ok
  end

  def set_in_memory(key, value), do: :ets.insert(:in_memory, {key, value})
  def get_in_memory(key), do: :ets.lookup(:in_memory, key)

  def create_file(path), do: :dets.open_file(:file, [{:file, to_charlist(path)}])
  def close_file(), do: :dets.close(:file)
  def set_file(key, value), do: :dets.insert(:file, {key, value})
  def get_file(key), do: :dets.lookup(:file, key)

  def create_distributed() do
    node_list = Node.list() ++ [Node.self()]
    :mnesia.create_schema(node_list)
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
