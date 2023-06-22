defmodule DemoTime.Demo3 do
  require Logger
  alias DemoTime.Docker

  def go do
    container = Docker.find("demo_time-postgres-1")
    Logger.info("Found container: #{inspect(container)}")

    Logger.info("Running queries with dead container #{container["Id"]}")
    Docker.kill(container)
    :timer.sleep(1000)
    Logger.info("Starting container #{container["Id"]}")
    Docker.start(container)
  end
end

defmodule DemoTime.Docker do
  @opts [:binary, active: false, reuseaddr: true]

  def find(name) do
    {:ok, socket} = :gen_tcp.connect({:local, '/var/run/docker.sock'}, 0, @opts)
    cmd = "GET /containers/json HTTP/1.1\r\nHost: localhost\r\n\r\n"
    :gen_tcp.send(socket, cmd)
    resp = receive_response(socket)

    resp
    |> String.replace("\n", "")
    |> String.split("\r")
    |> Enum.drop_while(&(&1 != ""))
    |> Enum.drop(2)
    |> hd()
    |> Jason.decode!()
    |> Enum.find(fn %{"Names" => names} -> Enum.any?(names, &(&1 == "/#{name}")) end)
  end

  def kill(container) do
    {:ok, socket} = :gen_tcp.connect({:local, '/var/run/docker.sock'}, 0, @opts)
    cmd = "POST /containers/#{container["Id"]}/kill HTTP/1.1\r\nHost: localhost\r\n\r\n"
    :gen_tcp.send(socket, cmd)
  end

  def start(container) do
    {:ok, socket} = :gen_tcp.connect({:local, '/var/run/docker.sock'}, 0, @opts)
    cmd = "POST /containers/#{container["Id"]}/start HTTP/1.1\r\nHost: localhost\r\n\r\n"
    :gen_tcp.send(socket, cmd)
  end

  defp receive_response(socket, buffer \\ "", stop \\ false)
  defp receive_response(_, buffer, true), do: buffer

  defp receive_response(socket, buffer, false) do
    case :gen_tcp.recv(socket, 0, 5000) do
      {:ok, data} -> receive_response(socket, buffer <> data, String.contains?(data, "0\r\n\r\n"))
      {:error, :timeout} -> buffer
    end
  end
end
