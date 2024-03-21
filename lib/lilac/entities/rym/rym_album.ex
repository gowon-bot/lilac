defmodule Lilac.RYM.Album do
  use Ecto.Schema

  schema "rate_your_music_albums" do
    field :rate_your_music_id, :string
    field :release_year, :integer

    field :title, :string
    field :artist_name, :string
    field :artist_native_name, :string

    has_many :ratings, Lilac.RYM.Rating, foreign_key: :rate_your_music_album_id
    many_to_many :albums, Lilac.Album, join_through: "rate_your_music_album_albums"
  end
end
