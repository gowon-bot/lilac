defmodule Lilac.AlbumCount do
  use Ecto.Schema

  schema("album_counts") do
    field :playcount, :integer

    belongs_to :album, Lilac.Album
    belongs_to :user, Lilac.User
  end
end
