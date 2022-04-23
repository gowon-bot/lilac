defmodule Lilac.Album do
  use Ecto.Schema

  schema "albums" do
    field :name, :string
    belongs_to :artist, Lilac.Artist

    has_many :tracks, Lilac.Track

    timestamps()
  end
end
