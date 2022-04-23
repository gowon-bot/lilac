defmodule Lilac.Repo.Migrations.AddAlbumsTable do
  use Ecto.Migration

  def change do
    create table(:albums) do
      add :name, :string
      add :artist_id, references(:artists)

      timestamps()
    end
  end
end
