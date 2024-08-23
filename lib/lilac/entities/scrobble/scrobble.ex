defmodule Lilac.Scrobble do
  use Ecto.Schema

  schema "scrobbles" do
    field(:scrobbled_at, :utc_datetime)
    field(:artist_name, :string)
    field(:album_name, :string)
    field(:track_name, :string)

    belongs_to :artist, Lilac.Artist
    belongs_to :album, Lilac.Album
    belongs_to :track, Lilac.Album

    belongs_to :user, Lilac.User
  end
end
