defmodule DemoTime.Thing do
  use Ecto.Schema
  import Ecto.Changeset

  schema "things" do
    field(:name, :string)
  end

  def changeset(thing, attrs), do: cast(thing, attrs, [:name])
end
