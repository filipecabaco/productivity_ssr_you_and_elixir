defmodule DemoTimeWeb.Presence do
  use Phoenix.Presence,
    otp_app: :demo_time,
    pubsub_server: DemoTime.PubSub
end
