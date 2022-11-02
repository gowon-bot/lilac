defmodule Lilac.ArtistTag do
  use Ecto.Schema

  schema "artist_tags" do
    belongs_to :artist, Lilac.Artist
    belongs_to :tag, Lilac.Tag
  end
end
