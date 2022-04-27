defmodule Lilac.Album do
  use Ecto.Schema

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

    timestamps()
  end
end
