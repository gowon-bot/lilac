defmodule Lilac.Artist do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  schema "artists" do
    field :name, :string
    field :checked_for_tags, :boolean

    has_many :albums, Lilac.Album
    has_many :tracks, Lilac.Track

    has_many :artist_counts, Lilac.ArtistCount

    many_to_many :tags, Lilac.Tag, join_through: "artist_tags"
  end
end
