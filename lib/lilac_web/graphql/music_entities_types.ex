defmodule LilacWeb.Schema.MusicEntitiesTypes do
  use Absinthe.Schema.Notation

  object :artist do
    field :name, non_null(:id)
  end

  object :album do
    field :name, non_null(:id)
    field :artist, :artist
  end

  object :track do
    field :name, non_null(:id)
    field :artist, non_null(:artist)
    field :album, :album
  end
end
