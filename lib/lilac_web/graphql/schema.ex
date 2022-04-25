defmodule LilacWeb.Schema do
  use Absinthe.Schema

  import_types(LilacWeb.Schema.MusicEntitiesTypes)

  alias LilacWeb.Resolvers

  query do
    # Music entities
    field :all_artists, non_null(list_of(non_null(:artist))) do
      resolve(&Resolvers.Artists.all_artists/3)
    end

    field :all_albums, non_null(list_of(non_null(:album))) do
      arg(:artist, :string)

      resolve(&Resolvers.Albums.all_albums/3)
    end

    field :all_tracks, non_null(list_of(non_null(:track))) do
      resolve(&Resolvers.Tracks.all_tracks/3)
    end
  end

  mutation do
    field :index, :string do
      arg(:username, :string)

      resolve(&Resolvers.User.index/3)
    end

    field :update, :string do
      arg(:username, :string)

      resolve(&Resolvers.User.index/3)
    end
  end
end
