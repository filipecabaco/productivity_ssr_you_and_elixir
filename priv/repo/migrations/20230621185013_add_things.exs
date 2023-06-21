defmodule DemoTime.Repo.Migrations.AddThings do
  use Ecto.Migration

  def change do
    create table(:things) do
      add :name, :string
    end
  end
end
