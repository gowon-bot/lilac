defmodule LilacWeb.Schema.Types do
  use Absinthe.Schema.Notation

  scalar :date do
    description("Unix timestamp")
    parse(&DateTime.from_unix/3)
    serialize(&DateTime.to_unix/1)
  end

  object :artist do
    field(:id, non_null(:id))
    field(:name, non_null(:string))

    field(:tags, non_null(list_of(non_null(:tag))))
  end

  object :album do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:artist, :artist)
  end

  object :track do
    field(:id, non_null(:id))
    field(:name, non_null(:string))
    field(:artist, non_null(:artist))
    field(:album, :album)
  end

  object :ambiguous_track do
    field(:artist, non_null(:artist))
    field(:name, non_null(:string))
  end

  object :user do
    field(:id, non_null(:id))
    field(:username, non_null(:string))
    field(:discord_id, non_null(:string))
    field(:privacy, non_null(:privacy))
    field(:has_premium, non_null(:boolean))

    field(:last_synced, :date)
    field(:is_syncing, :boolean)
  end

  object :guild_member do
    field(:guild_id, non_null(:string))
    field(:user, non_null(:user))
  end

  object :scrobble do
    field(:scrobbled_at, :date)

    field(:artist, :artist)
    field(:album, :album)
    field(:track, :track)
    field(:user, :user)
  end

  object :tag do
    field(:id, non_null(:integer))
    field(:name, non_null(:string))
    field(:occurrences, :integer)
  end

  enum :privacy do
    value(:private, description: "No information is displayed")
    value(:discord, description: "Discord tag is displayed")
    value(:fmusername, description: "Last.fm username is displayed")
    value(:both, description: "Discord tag is displayed and last.fm is linked")
    value(:unset, description: "Default value; same as private")
  end

  # Sync
  object :sync_progress do
    field(:action, non_null(:string))
    field(:stage, non_null(:string))
    field(:current, non_null(:integer))
    field(:total, non_null(:integer))
  end

  # Counts
  object :artist_count do
    field(:artist, non_null(:artist))
    field(:playcount, non_null(:integer))
    field(:first_scrobbled, :date)
    field(:last_scrobbled, :date)

    field(:user, non_null(:user))
  end

  object :album_count do
    field(:album, non_null(:album))
    field(:playcount, non_null(:integer))
    field(:first_scrobbled, :date)
    field(:last_scrobbled, :date)

    field(:user, non_null(:user))
  end

  object :track_count do
    field(:track, non_null(:track))
    field(:playcount, non_null(:integer))
    field(:first_scrobbled, :date)
    field(:last_scrobbled, :date)

    field(:user, non_null(:user))
  end

  object :ambiguous_track_count do
    field(:track, non_null(:ambiguous_track))
    field(:playcount, non_null(:integer))
    field(:first_scrobbled, :date)
    field(:last_scrobbled, :date)

    field(:user, non_null(:user))
  end

  # Who knows
  object :who_knows_row do
    field(:user, non_null(:user))
    field(:playcount, non_null(:integer))
  end

  object :who_knows_artist_response do
    field(:rows, non_null(list_of(non_null(:who_knows_row))))
    field(:artist, non_null(:artist))
  end

  object :who_knows_album_response do
    field(:rows, non_null(list_of(non_null(:who_knows_row))))
    field(:album, non_null(:album))
  end

  object :who_knows_track_response do
    field(:rows, non_null(list_of(non_null(:who_knows_row))))
    field(:track, non_null(:track))
  end

  object :who_knows_artist_rank do
    field(:artist, :artist)

    field(:rank, non_null(:integer))
    field(:playcount, non_null(:integer))
    field(:total_listeners, non_null(:integer))

    field(:above, :artist_count)
    field(:below, :artist_count)
  end

  object :who_knows_album_rank do
    field(:album, :album)

    field(:rank, non_null(:integer))
    field(:playcount, non_null(:integer))
    field(:total_listeners, non_null(:integer))

    field(:above, :album_count)
    field(:below, :album_count)
  end

  object :who_knows_track_rank do
    field(:track, :ambiguous_track)

    field(:rank, non_null(:integer))
    field(:playcount, non_null(:integer))
    field(:total_listeners, non_null(:integer))

    field(:above, :ambiguous_track_count)
    field(:below, :ambiguous_track_count)
  end

  # Who first
  object :who_first_row do
    field(:user, non_null(:user))
    field(:first_scrobbled, non_null(:date))
    field(:last_scrobbled, non_null(:date))
  end

  object :who_first_artist_response do
    field(:rows, non_null(list_of(non_null(:who_first_row))))
    field(:artist, non_null(:artist))
  end

  object :who_first_artist_rank do
    field(:artist, :artist)

    field(:rank, non_null(:integer))
    field(:first_scrobbled, non_null(:date))
    field(:last_scrobbled, non_null(:date))
    field(:total_listeners, non_null(:integer))
  end

  # Pages
  object(:scrobbles_page) do
    field(:scrobbles, non_null(list_of(non_null(:scrobble))))
    field(:pagination, non_null(:pagination))
  end

  object(:artists_page) do
    field(:artists, non_null(list_of(non_null(:artist))))
    field(:pagination, non_null(:pagination))
  end

  object(:artist_counts_page) do
    field(:artist_counts, non_null(list_of(non_null(:artist_count))))
    field(:pagination, non_null(:pagination))
  end

  object(:albums_page) do
    field(:albums, non_null(list_of(non_null(:album))))
    field(:pagination, non_null(:pagination))
  end

  object(:album_counts_page) do
    field(:album_counts, non_null(list_of(non_null(:album_count))))
    field(:pagination, non_null(:pagination))
  end

  object(:tracks_page) do
    field(:tracks, non_null(list_of(non_null(:track))))
    field(:pagination, non_null(:pagination))
  end

  object(:ambiguous_tracks_page) do
    field(:tracks, non_null(list_of(non_null(:ambiguous_track))))
    field(:pagination, non_null(:pagination))
  end

  object(:track_counts_page) do
    field(:track_counts, non_null(list_of(non_null(:track_count))))
    field(:pagination, non_null(:pagination))
  end

  object(:ambiguous_track_counts_page) do
    field(:track_counts, non_null(list_of(non_null(:ambiguous_track_count))))
    field(:pagination, non_null(:pagination))
  end

  object(:tags_page) do
    field(:tags, non_null(list_of(non_null(:tag))))
    field(:pagination, non_null(:pagination))
  end

  object(:pagination) do
    field(:current_page, non_null(:integer))
    field(:total_pages, non_null(:integer))
    field(:total_items, non_null(:integer))
    field(:per_page, non_null(:integer))
  end

  # ======
  # Inputs
  # ======

  # User

  input_object :user_input do
    field(:id, :id)
    field(:username, :string)
    field(:discord_id, :string)
  end

  # Who knows
  input_object :who_knows_input do
    field(:guild_id, :string)
    field(:limit, :integer)
    field(:user_ids, list_of(non_null(:string)))
  end

  input_object :who_first_input do
    field(:guild_id, :string)
    field(:limit, :integer)
    field(:user_ids, list_of(non_null(:string)))
    field(:reverse, :boolean)
  end

  # Music entities
  input_object :artist_input do
    field(:name, :string)
  end

  input_object :album_input do
    field(:name, :string)
    field(:artist, :artist_input)
  end

  input_object :track_input do
    field(:name, :string)
    field(:artist, :artist_input)
    field(:album, :album_input)
  end

  input_object :page_input do
    field(:page, non_null(:integer))
    field(:per_page, non_null(:integer))
  end

  input_object :tag_input do
    field(:name, non_null(:string))
  end

  input_object :user_modifications do
    field(:username, :string)
    field(:discord_id, :string)
    field(:privacy, :privacy)
    field(:last_fm_session, :privacy)
    field(:has_premium, :boolean)
  end

  # Filters

  input_object :scrobbles_filters do
    field(:user, :user_input)
    field(:artist, :artist_input)
    field(:album, :album_input)
    field(:track, :track_input)
    field(:pagination, :page_input)
  end

  input_object :artists_filters do
    field(:inputs, list_of(non_null(:artist_input)))
    field(:tags, list_of(non_null(:tag_input)))
    field(:pagination, :page_input)

    field(:fetch_tags_for_missing, :boolean)
  end

  input_object :artist_counts_filters do
    field(:artists, list_of(non_null(:artist_input)))
    field(:tags, list_of(non_null(:tag_input)))
    field(:users, list_of(non_null(:user_input)))
    field(:pagination, :page_input)

    field(:fetch_tags_for_missing, :boolean)
  end

  input_object :albums_filters do
    field(:album, :album_input)
    field(:pagination, :page_input)
  end

  input_object :album_counts_filters do
    field(:album, :album_input)
    field(:users, list_of(non_null(:user_input)))
    field(:pagination, :page_input)
  end

  input_object :tracks_filters do
    field(:track, :track_input)
    field(:pagination, :page_input)
  end

  input_object :track_counts_filters do
    field(:track, :track_input)
    field(:users, list_of(non_null(:user_input)))
    field(:pagination, :page_input)
  end

  input_object :tags_filters do
    field(:inputs, list_of(non_null(:tag_input)))
    field(:artists, list_of(non_null(:artist_input)))
    field(:pagination, :page_input)

    field(:fetch_tags_for_missing, :boolean)
  end
end
