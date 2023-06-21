# DemoTime

## Demo 1

```
PORT=4000 iex --name s1@127.0.0.1 -S mix phx.server
PORT=4001 iex --name s2@127.0.0.1 -S mix phx.server
PORT=4002 iex --name s3@127.0.0.1 -S mix phx.server

# From any machine
DemoTime.Demo1.broadcast(:message_queue, "test")
```
