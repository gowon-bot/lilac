defmodule Lilac.Scrobble do
  use Ecto.Schema

  schema "scrobbles" do
    field :scrobbled_at, :utc_datetime

    belongs_to :artist, Lilac.Artist
    belongs_to :album, Lilac.Album
    belongs_to :track, Lilac.Album

    belongs_to :user, Lilac.User
  end
end
