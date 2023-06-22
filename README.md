# DemoTime

## Demo 1

```
PORT=4000 iex --name s1@127.0.0.1 -S mix phx.server
PORT=4001 iex --name s2@127.0.0.1 -S mix phx.server
PORT=4002 iex --name s3@127.0.0.1 -S mix phx.server

# From any machine
DemoTime.Demo1.broadcast(:message_queue, "test")
```

## Demo 2

```
DemoTime.Demo2.create_in_memory()
DemoTime.Demo2.set_in_memory(:a, "1")
DemoTime.Demo2.get_in_memory(:a)

DemoTime.Demo2.create_file(".db")
DemoTime.Demo2.set_file(:a, "1")
DemoTime.Demo2.get_file(:a)
DemoTime.Demo2.close_file()

DemoTime.Demo2.create_distributed()
DemoTime.Demo2.set_distributed(:a, "1")

# From another node
DemoTime.Demo2.get_distributed(:a)
```
