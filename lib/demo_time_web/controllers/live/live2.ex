defmodule DemoTimeWeb.Live.Live2 do
  use DemoTimeWeb, :live_view

  alias Avatarex
  alias Avatarex.Sets.Kitty
  alias DemoTimeWeb.Presence
  alias DemoTimeWeb.Monitor

  @sentences "sentences.txt" |> File.read!() |> String.split("\n")

  def mount(_params, _session, socket) do
    DemoTimeWeb.Endpoint.subscribe("messages")
    Phoenix.PubSub.subscribe(DemoTime.PubSub, "presence")

    if connected?(socket) do
      online_at = DateTime.utc_now() |> Calendar.strftime("%H:%M:%S")
      Presence.track(socket.transport_pid, "presence", socket.id, %{online_at: online_at})
      Monitor.monitor(socket.transport_pid, socket.id)
    end

    users =
      "presence"
      |> Presence.list()
      |> Enum.map(&handle_users/1)
      |> Enum.filter(&(&1 != nil))
      |> MapSet.new()

    socket =
      socket
      |> assign(:users, users)
      |> stream(:messages, [])

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[80vh]">
      <div class="flex grow-1 h-full">
        <div>
          <ul>
            <li :for={%{avatar: avatar, online_at: online_at} <- @users} class="flex items-center w-28">
              <img src={"data:image/png;base64,#{avatar}"} class="h-8 w-8" />
              <div><%= online_at %></div>
            </li>
          </ul>
        </div>
        <div
          class="grow-1 h-full w-full overflow-scroll border-2 shadow rounded p-4 border-slate-200"
          phx-update="stream"
          id="messages"
          phx-hook="AutoScroll"
        >
          <div :for={{dom_id, %{message: message}} <- @streams.messages} id={dom_id}>
            <%= message %>
          </div>
        </div>
      </div>
      <.simple_form :let={f} for={%{"message" => ""}} phx-submit="new_message">
        <.input field={f["message"]} />
      </.simple_form>
      <button
        class="right-4 bottom-4 fixed bg-brand hover:bg-brand-light rounded p-2 text-white font-bold"
        phx-click="chaos"
      >
        Chaos
      </button>
    </div>
    """
  end

  ## Messages
  def handle_event("new_message", %{"message" => message}, socket) do
    message = %{id: DateTime.utc_now(), message: message}
    DemoTimeWeb.Endpoint.broadcast("messages", "new_message", {socket.id, message})

    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_to_bottom", %{})

    {:noreply, socket}
  end

  def handle_event("chaos", _, socket) do
    DemoTimeWeb.Endpoint.broadcast("messages", "chaos", nil)
    {:noreply, socket}
  end

  def handle_info(
        %{topic: "messages", event: "new_message", payload: {id, _}},
        %{socket: id} = socket
      ) do
    {:noreply, socket}
  end

  def handle_info(%{topic: "messages", event: "new_message", payload: {_, message}}, socket) do
    {:noreply, stream_insert(socket, :messages, message)}
  end

  def handle_info(%{topic: "messages", event: "chaos"}, socket) do
    message = %{id: DateTime.utc_now(), message: Enum.random(@sentences)}
    DemoTimeWeb.Endpoint.broadcast("messages", "new_message", {socket.id, message})

    :timer.sleep(10)

    DemoTimeWeb.Endpoint.broadcast("messages", "chaos", nil)

    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_to_bottom", %{})

    {:noreply, socket}
  end

  ## Presence
  def handle_info(
        %{topic: "presence", event: "presence_diff", payload: %{joins: joins}},
        %{assigns: %{users: users}} = socket
      )
      when joins != [] do
    new_users =
      joins
      |> Enum.map(&handle_users/1)
      |> Enum.filter(&(&1 != nil))
      |> MapSet.new()

    {:noreply, assign(socket, :users, MapSet.union(users, new_users))}
  end

  def handle_info(
        %{topic: "presence", event: "presence_diff", payload: %{leaves: leaves}},
        %{assigns: %{users: users}} = socket
      )
      when leaves != [] do
    users = Enum.reduce(leaves, users, &MapSet.reject(&2, fn %{id: id} -> id == &1 end))
    {:noreply, assign(socket, :users, users)}
  end

  defp handle_users({id, %{metas: metas}}) do
    metas
    |> hd()
    |> then(fn %{online_at: online_at} ->
      id
      |> Avatarex.render(Kitty, :kitty, ".")
      |> Avatarex.write()

      path = "#{id}_kitty.png"

      case File.read(path) do
        {:ok, file} ->
          avatar = Base.encode64(file)
          File.rm(path)
          %{id: id, avatar: avatar, online_at: online_at}

        _ ->
          nil
      end
    end)
  end
end
