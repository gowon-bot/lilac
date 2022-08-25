defmodule LilacWeb.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :date do
    description("Unix timestamp")
    parse(&DateTime.from_unix/3)
    serialize(&DateTime.to_unix/1)
  end

  object :artist do
    field :id, non_null(:id)
    field :name, non_null(:string)
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
    value(:fm_username, description: "Last.fm username is displayed")
    value(:both, description: "Discord tag is displayed and last.fm is linked")
    value(:unset, description: "Default value; same as private")
  end

  # Indexing
  object :indexing_progress do
    field :page, non_null(:integer)
    field :total_pages, non_null(:integer)
    field :action, non_null(:string)
  end

  # Counts
  object :artist_count do
    field :artist, non_null(:artist)
    field :playcount, non_null(:integer)

    field :user, non_null(:user)
  end

  object :album_count do
    field :album, non_null(:album)
    field :playcount, non_null(:integer)

    field :user, non_null(:user)
  end

  # Who knows
  object :who_knows_row do
    field :user, non_null(:user)
    field :playcount, non_null(:integer)
  end

  object :who_knows_artist_response do
    field :rows, non_null(list_of(non_null(:who_knows_row)))
    field :artist, non_null(:artist)
  end

  object :who_knows_album_response do
    field :rows, non_null(list_of(non_null(:who_knows_row)))
    field :album, non_null(:album)
  end

  object :who_knows_artist_rank do
    field :artist, :artist

    field :rank, non_null(:integer)
    field :playcount, non_null(:integer)
    field :total_listeners, non_null(:integer)

    field :above, :artist_count
    field :below, :artist_count
  end

  object :who_knows_album_rank do
    field :artist, :album

    field :rank, non_null(:integer)
    field :playcount, non_null(:integer)
    field :total_listeners, non_null(:integer)

    field :above, :album_count
    field :below, :album_count
  end

  # ======
  # Inputs
  # ======

  # User

  input_object :user_input do
    field :id, :id
    field :username, :string
    field :discord_id, :string
  end

  # Who knows
  input_object :who_knows_input do
    field :guild_id, :string
    field :limit, :integer
    field :user_ids, list_of(non_null(:string))
  end

  # Music entities
  input_object :artist_input do
    field :name, :string
  end

  input_object :album_input do
    field :name, :string
    field :artist, :artist_input
  end
end
