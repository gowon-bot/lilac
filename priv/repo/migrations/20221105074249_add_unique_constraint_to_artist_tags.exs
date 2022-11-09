defmodule Lilac.Repo.Migrations.AddUniqueConstraintToArtistTags do
  use Ecto.Migration

  def change do
    create unique_index(:artist_tags, [:artist_id, :tag_id])
  end
end
