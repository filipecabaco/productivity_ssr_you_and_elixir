defmodule DemoTimeWeb.Live.Live1 do
  use DemoTimeWeb, :live_view

  @sentences "sentences.txt" |> File.read!() |> String.split("\n")

  def mount(_params, _session, socket) do
    DemoTimeWeb.Endpoint.subscribe("messages")
    {:ok, stream(socket, :messages, [])}
  end

  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-[80vh]">
      <div
        class="grow-1 h-full overflow-scroll border-2 shadow rounded p-4 border-slate-200"
        phx-update="stream"
        id="messages"
        phx-hook="AutoScroll"
      >
        <div :for={{dom_id, %{message: message}} <- @streams.messages} id={dom_id}>
          <%= message %>
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
    message = %{
      id: DateTime.utc_now(),
      message: Enum.random(@sentences)
    }

    DemoTimeWeb.Endpoint.broadcast("messages", "new_message", {socket.id, message})

    :timer.sleep(100)

    DemoTimeWeb.Endpoint.broadcast("messages", "chaos", nil)

    socket =
      socket
      |> stream_insert(:messages, message)
      |> push_event("scroll_to_bottom", %{})

    {:noreply, socket}
  end
end
