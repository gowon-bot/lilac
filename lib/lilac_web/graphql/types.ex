defmodule LilacWeb.Schema.Types do
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

  object :indexing_progress do
    field :page, non_null(:integer)
    field :total_pages, non_null(:integer)
    field :action, non_null(:string)
  end

  # Inputs

  input_object :user_input do
    field :id, :id
    field :username, :string
    field :discord_id, :string
  end
end
