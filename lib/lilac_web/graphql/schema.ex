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

    field :artists, non_null(:artists_page) do
      arg(:filters, :artists_filters)

      resolve(&Resolvers.Artists.list/3)
    end

    # To be deprecated/standardized
    field :all_albums, non_null(list_of(non_null(:album))) do
      arg(:artist, :string)

      resolve(&Resolvers.Albums.all_albums/3)
    end

    field :all_tracks, non_null(list_of(non_null(:track))) do
      resolve(&Resolvers.Tracks.all_tracks/3)
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
    field :index, :string do
      arg(:user, :user_input)

      resolve(&Resolvers.User.index/3)
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
  end

  subscription do
    field :index, :indexing_progress do
      arg(:user, non_null(:user_input))

      config(fn args, _ ->
        user = Lilac.Repo.get_by!(Lilac.User, args.user)

        {:ok, topic: "#{user.id}"}
      end)

      resolve(fn progress, _, _ -> {:ok, progress} end)
    end
  end
end
