defmodule Lilac.Repo.Migrations.RenameIndexingToSyncing do
  use Ecto.Migration

  def change do
    rename(table(:users), :last_indexed, to: :last_synced)
  end
end
