defmodule Lilac.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string

    many_to_many :artists, Lilac.Artist, join_through: "artist_tag"
  end
end
