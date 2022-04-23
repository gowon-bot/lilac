defmodule Lilac.Artist do
  use Ecto.Schema

  schema "artists" do
    field :name, :string

    has_many :albums, Lilac.Album
    has_many :tracks, Lilac.Track

    timestamps()
  end
end
