defmodule Lilac.Track do
  use Ecto.Schema

  @typedoc """
  Represents a track to be used in a select query
  """
  @type queryable :: %{name: String.t(), artist_id: integer, album_id: integer() | nil}

  @typedoc """
  Represents a track created from a scrobble
  """
  @type raw :: %{name: String.t(), artist: String.t(), album: String.t() | nil}

  schema "tracks" do
    field :name, :string

    belongs_to :artist, Lilac.Artist
    belongs_to :album, Lilac.Album

    timestamps()
  end
end
