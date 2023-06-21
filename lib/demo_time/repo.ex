defmodule DemoTime.Repo do
  use Ecto.Repo,
    otp_app: :demo_time,
    adapter: Ecto.Adapters.Postgres
end
