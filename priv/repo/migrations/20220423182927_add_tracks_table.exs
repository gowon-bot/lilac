defmodule Lilac.Repo.Migrations.AddTracksTable do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :name, :citext
      add :artist_id, references(:artists)
      add :album_id, references(:albums), null: true

      timestamps()
    end
  end
end
