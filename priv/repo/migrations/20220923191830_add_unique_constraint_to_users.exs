defmodule Lilac.Repo.Migrations.AddUniqueConstraintToUsers do
  use Ecto.Migration

  def change do
    create unique_index(:users, [:discord_id])
  end
end
