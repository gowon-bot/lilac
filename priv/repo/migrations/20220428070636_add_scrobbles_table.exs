defmodule Lilac.Repo.Migrations.AddScrobblesTable do
  use Ecto.Migration

  def change do
    create table(:scrobbles) do
      add :scrobbled_at, :utc_datetime

      add :artist_id, references(:artists)
      add :album_id, references(:albums), null: true
      add :track_id, references(:tracks)

      add :user_id, references(:users)
    end
  end
end
