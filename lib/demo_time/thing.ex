defmodule DemoTime.Thing do
  use Ecto.Schema

  schema "things" do
    field :name, :string
  end
end
