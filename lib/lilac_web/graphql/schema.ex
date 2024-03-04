defmodule LilacWeb.Schema do
  use Absinthe.Schema

  import_types(LilacWeb.Schema.Types)

  alias LilacWeb.Resolvers

  query do
    # Misc
    field :ping, :string do
      resolve(&Resolvers.Misc.ping/3)
    end

    # Users
    field :users, non_null(list_of(non_null(:user))) do
      arg(:filters, :user_input)

      resolve(&Resolvers.User.users/3)
    end

    # Entities
    field :artists, non_null(:artists_page) do
      arg(:filters, :artists_filters)

      resolve(&Resolvers.Artists.list/3)
    end

    field :artist_counts, non_null(:artist_counts_page) do
      arg(:filters, :artist_counts_filters)

      resolve(&Resolvers.Artists.list_counts/3)
    end

    field :albums, non_null(:albums_page) do
      arg(:filters, :albums_filters)

      resolve(&Resolvers.Albums.list/3)
    end

    field :album_counts, non_null(:album_counts_page) do
      arg(:filters, :album_counts_filters)

      resolve(&Resolvers.Albums.list_counts/3)
    end

    field :tracks, non_null(:tracks_page) do
      arg(:filters, :tracks_filters)

      resolve(&Resolvers.Tracks.list/3)
    end

    field :track_counts, non_null(:track_counts_page) do
      arg(:filters, :track_counts_filters)

      resolve(&Resolvers.Tracks.list_counts/3)
    end

    field :tags, non_null(:tags_page) do
      arg(:filters, :tags_filters)

      resolve(&Resolvers.Tags.list/3)
    end

    # Entities
    field :scrobbles, non_null(:scrobbles_page) do
      arg(:filters, :scrobbles_filters)

      resolve(&Resolvers.Scrobbles.list/3)
    end

    # Who knows
    field :who_knows_artist, non_null(:who_knows_artist_response) do
      arg(:artist, :artist_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_artist/3)
    end

    field :who_knows_artist_rank, non_null(:who_knows_artist_rank) do
      arg(:artist, :artist_input)
      arg(:user, :user_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_artist_rank/3)
    end

    field :who_knows_album, non_null(:who_knows_album_response) do
      arg(:album, :album_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_album/3)
    end

    field :who_knows_album_rank, non_null(:who_knows_album_rank) do
      arg(:album, :album_input)
      arg(:user, :user_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_album_rank/3)
    end

    field :who_knows_track, non_null(:who_knows_track_response) do
      arg(:track, :track_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_track/3)
    end

    field :who_knows_track_rank, non_null(:who_knows_track_rank) do
      arg(:track, :track_input)
      arg(:user, :user_input)
      arg(:settings, :who_knows_input)

      resolve(&Resolvers.WhoKnows.who_knows_track_rank/3)
    end
  end

  mutation do
    field :sync, :string do
      arg(:user, :user_input)
      arg(:force_restart, :boolean)

      resolve(&Resolvers.User.sync/3)
    end

    field :update, :string do
      arg(:user, :user_input)

      resolve(&Resolvers.User.update/3)
    end

    field :tag_artists, :integer do
      arg(:artists, list_of(non_null(:artist_input)))
      arg(:tags, list_of(non_null(:tag_input)))
      arg(:mark_as_checked, :boolean)

      resolve(&Resolvers.Tags.tagArtists/3)
    end

    field :modify_user, :user do
      arg(:user, :user_input)
      arg(:modifications, :user_modifications)

      resolve(&Resolvers.User.modify/3)
    end

    field :login, :user do
      arg(:username, non_null(:string))
      arg(:last_fm_session, non_null(:string))
      arg(:discord_id, non_null(:string))

      resolve(&Resolvers.User.login/3)
    end

    field :logout, :integer do
      arg(:user, :user_input)

      resolve(&Resolvers.User.logout/3)
    end

    # Guild management

    field :add_user_to_guild, :guild_member do
      arg(:discord_id, non_null(:string))
      arg(:guild_id, non_null(:string))

      resolve(&Resolvers.GuildMember.add_to_guild/3)
    end

    field :remove_user_from_guild, :integer do
      arg(:discord_id, non_null(:string))
      arg(:guild_id, non_null(:string))

      resolve(&Resolvers.GuildMember.remove_from_guild/3)
    end

    field :sync_guild, :integer do
      arg(:guild_id, non_null(:string))
      arg(:discord_ids, :string |> non_null |> list_of |> non_null)

      resolve(&Resolvers.GuildMember.sync_guild/3)
    end

    field :clear_guild, :integer do
      arg(:guild_id, non_null(:string))

      resolve(&Resolvers.GuildMember.clear_guild/3)
    end
  end

  subscription do
    field :sync, :sync_progress do
      arg(:user, non_null(:user_input))

      config(fn args, _ ->
        user = Lilac.Repo.get_by!(Lilac.User, args.user)

        {:ok, topic: "#{user.id}"}
      end)

      resolve(fn progress, _, _ -> {:ok, progress} end)
    end
  end
end
