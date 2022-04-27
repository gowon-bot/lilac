defmodule Lilac.ArtistCount do
  use Ecto.Schema

  schema("artist_counts") do
    field :playcount, :integer

    belongs_to :artist, Lilac.Artist
    belongs_to :user, Lilac.User
  end
end
