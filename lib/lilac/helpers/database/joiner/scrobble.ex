defmodule Lilac.Joiner.Scrobble do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.Scrobble
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  @spec chained_maybe_join_track(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def chained_maybe_join_track(query, filters, info, select) do
    if Scrobble.Filters.has_track?(filters) ||
         Introspection.has_field?(info, Fields.Scrobble.track()) do
      query
      |> join_track(select)
      |> join_album(select)
      |> join_artist(select)
    else
      query |> chained_maybe_join_album(filters, info, select)
    end
  end

  @spec chained_maybe_join_album(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_album(query, filters, info, select) do
    if Scrobble.Filters.has_album?(filters) ||
         Introspection.has_field?(info, Fields.Scrobble.album()) do
      query
      |> join_album(select)
      |> join_artist(select)
    else
      query |> maybe_join_artist(filters, info, select)
    end
  end

  @spec maybe_join_artist(Ecto.Query.t(), Scrobble.Filters.t(), %Absinthe.Resolution{}, boolean) ::
          Ecto.Query.t()
  defp maybe_join_artist(query, filters, info, select) do
    if Scrobble.Filters.has_artist?(filters) ||
         Introspection.has_field?(info, Fields.Scrobble.artist()) do
      query
      |> join_artist(select)
    else
      query
    end
  end

  @spec maybe_join_user(Ecto.Query.t(), Scrobble.Filters.t(), %Absinthe.Resolution{}, boolean) ::
          Ecto.Query.t()
  def maybe_join_user(query, filters, info, select) do
    if Scrobble.Filters.has_user?(filters) ||
         Introspection.has_field?(info, Fields.Scrobble.user()) do
      query
      |> join_user(select)
    else
      query
    end
  end

  @spec join_artist(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_artist(query, select) do
    joined_query =
      query
      |> join(:inner, [s], a in Lilac.Artist, on: s.artist_id == a.id, as: :artist)

    if select do
      joined_query |> select_merge([artist: a], %{artist: a})
    else
      joined_query
    end
  end

  @spec join_album(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_album(query, select) do
    joined_query =
      query
      |> join(:inner, [s], l in Lilac.Album, on: s.album_id == l.id, as: :album)

    if select do
      joined_query |> select_merge([album: l], %{album: l})
    else
      joined_query
    end
  end

  @spec join_track(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_track(query, select) do
    joined_query =
      query
      |> join(:inner, [s], t in Lilac.Track, on: s.track_id == t.id, as: :track)

    if select do
      joined_query |> select_merge([track: t], %{track: t})
    else
      joined_query
    end
  end

  @spec join_user(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_user(query, select) do
    joined_query =
      query
      |> join(:inner, [s], u in Lilac.User, on: s.user_id == u.id, as: :user)

    if select do
      joined_query |> select_merge([user: u], %{user: u})
    else
      joined_query
    end
  end
end
