import Config

port = String.to_integer(System.get_env("PORT") || "4000")
config :demo_time, DemoTimeWeb.Endpoint, http: [port: port]

enabled? = System.get_env("ENABLE_SAUCE") == "true"
config :demo_time, live3_sauce: enabled?
