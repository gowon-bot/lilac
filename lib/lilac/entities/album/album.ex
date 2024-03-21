defmodule Lilac.Album do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  @typedoc """
  Represents an album to be used in a select query
  """
  @type queryable :: %{name: String.t(), artist_id: integer}

  @typedoc """
  Represents an album created from a scrobble
  """
  @type raw :: %{name: String.t(), artist: String.t()}

  schema("albums") do
    field :name, :string
    belongs_to :artist, Lilac.Artist

    has_many :tracks, Lilac.Track
    has_many :album_counts, Lilac.AlbumCount

    many_to_many :rym_albums, Lilac.RYM.Album, join_through: "rate_your_music_album_albums"
  end
end
