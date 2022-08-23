defmodule LilacWeb.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :date do
    description("Unix timestamp")
    parse(&DateTime.from_unix/3)
    serialize(&DateTime.to_unix/1)
  end

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

  object :user do
    field :id, non_null(:id)
    field :username, non_null(:string)
    field :discord_id, non_null(:string)

    field :privacy, non_null(:privacy)
    field :last_indexed, :date
  end

  enum :privacy do
    value(:private, description: "No information is displayed")
    value(:discord, description: "Discord tag is displayed")
    value(:fmusername, description: "Last.fm username is displayed")
    value(:both, description: "Discord tag is displayed and last.fm is linked")
    value(:unset, description: "Default value; same as private")
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
