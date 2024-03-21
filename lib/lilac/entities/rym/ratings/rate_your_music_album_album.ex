defmodule Lilac.RYM.AlbumAlbum do
  use Ecto.Schema

  schema "rate_your_music_album_albums" do
    belongs_to :album, Lilac.Album
    belongs_to :rate_your_music_album, Lilac.RYM.Album
  end
end
