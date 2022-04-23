defmodule Lilac.Repo.Migrations.AddArtistsTable do
  use Ecto.Migration

  def change do
    create table(:artists) do
      add :name, :string

      timestamps()
    end
  end
end
