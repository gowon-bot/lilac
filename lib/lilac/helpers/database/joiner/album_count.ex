defmodule Lilac.Joiner.AlbumCount do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.AlbumCount
  alias Lilac.Scrobble
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  # Conditional methods

  @spec maybe_join_user(Ecto.Query.t(), AlbumCount.Filters.t(), %Absinthe.Resolution{}, boolean) ::
          Ecto.Query.t()
  def maybe_join_user(query, filters, info, select) do
    if AlbumCount.Filters.has_users?(filters) ||
         Introspection.has_field?(info, Fields.Album.Count.user()) do
      query
      |> join_user(select)
    else
      query
    end
  end

  @spec chained_maybe_join_album_artist(
          Ecto.Query.t(),
          AlbumCounts.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def chained_maybe_join_album_artist(query, filters, info, select) do
    if Lilac.Album.Filters.has_album_artist?(filters) ||
         Introspection.has_field?(info, Fields.Album.Count.album_artist()) do
      query
      |> join_album_artist(select)
    else
      query |> maybe_join_album(filters, info, select)
    end
  end

  @spec maybe_join_album(
          Ecto.Query.t(),
          AlbumCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp maybe_join_album(query, filters, info, select) do
    if AlbumCount.Filters.has_album?(filters) ||
         Introspection.has_field?(info, Fields.Album.Count.album_artist()) do
      query
      |> join_album(select)
    else
      query
    end
  end

  # join methods

  @spec join_album_artist(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_album_artist(query, select) do
    joined_query =
      query
      |> join(:inner, [album_count: ac], l in Lilac.Album, on: ac.album_id == l.id, as: :album)
      |> join(:inner, [album: l], a in Lilac.Artist, on: l.artist_id == a.id, as: :artist)

    if select do
      joined_query |> select_merge([album: l, artist: a], %{album: %{l | artist: a}})
    else
      joined_query
    end
  end

  @spec join_album(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_album(query, select) do
    joined_query =
      query
      |> join(:inner, [album_count: ac], l in Lilac.Album, on: ac.album_id == l.id, as: :album)

    if select do
      joined_query |> select_merge([album: l], %{album: l})
    else
      joined_query
    end
  end

  @spec join_user(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_user(query, select) do
    joined_query =
      query
      |> join(:inner, [album_count: ac], u in Lilac.User, on: ac.user_id == u.id, as: :user)

    if select do
      joined_query |> select_merge([user: u], %{user: u})
    else
      joined_query
    end
  end
end
