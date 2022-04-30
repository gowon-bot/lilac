defmodule Lilac.Artist do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  schema "artists" do
    field :name, :string

    has_many :albums, Lilac.Album
    has_many :tracks, Lilac.Track

    has_many :artist_counts, Lilac.ArtistCount

    timestamps()
  end
end
