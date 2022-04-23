defmodule Lilac.Track do
  use Ecto.Schema

  schema "tracks" do
    field :name, :string

    belongs_to :artist, Lilac.Artist
    belongs_to :album, Lilac.Album

    timestamps()
  end
end
