defmodule Lilac.Repo.Migrations.AddEntityNamesToScrobbles do
  use Ecto.Migration

  def change do
    alter table(:scrobbles) do
      add(:artist_name, :string)
      add(:album_name, :string)
      add(:track_name, :string)
    end
  end
end
