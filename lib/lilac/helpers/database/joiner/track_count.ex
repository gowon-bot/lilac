defmodule Lilac.Joiner.TrackCount do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.TrackCount
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  # Conditional methods

  @spec maybe_join_user(Ecto.Query.t(), TrackCount.Filters.t(), %Absinthe.Resolution{}, boolean) ::
          Ecto.Query.t()
  def maybe_join_user(query, filters, info, select) do
    if TrackCount.Filters.has_users?(filters) ||
         Introspection.has_field?(info, Fields.Track.Count.user()) do
      query
      |> join_user(select)
    else
      query
    end
  end

  @spec chained_maybe_join_album(
          Ecto.Query.t(),
          TrackCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def chained_maybe_join_album(query, filters, info, select) do
    if TrackCount.Filters.has_album?(filters) ||
         Introspection.has_field?(info, Fields.Track.Count.album()) do
      query
      |> join_track(select)
      |> join_artist(select)
      |> join_album(select)
    else
      query |> chained_maybe_join_artist(filters, info, select)
    end
  end

  @spec chained_maybe_join_artist(
          Ecto.Query.t(),
          TrackCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_artist(query, filters, info, select) do
    if TrackCount.Filters.has_artist?(filters) ||
         Introspection.has_field?(info, Fields.Track.Count.artist()) do
      query
      |> join_track(select)
      |> join_artist(select)
    else
      query |> chained_maybe_join_track(filters, info, select)
    end
  end

  @spec chained_maybe_join_track(
          Ecto.Query.t(),
          TrackCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_track(query, filters, info, select) do
    if TrackCount.Filters.has_track?(filters) ||
         Introspection.has_field?(info, Fields.Track.Count.track()) do
      query
      |> join_track(select)
    else
      query
    end
  end

  # Join methods

  @spec join_user(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_user(query, select) do
    joined_query =
      query
      |> join(:inner, [track_count: tc], u in Lilac.User, on: tc.user_id == u.id, as: :user)

    if select do
      joined_query |> select_merge([user: u], %{user: u})
    else
      joined_query
    end
  end

  @spec join_track(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_track(query, select) do
    joined_query =
      query
      |> join(:inner, [track_count: tc], t in Lilac.Track, on: tc.track_id == t.id, as: :track)

    if select do
      joined_query |> select_merge([track: t], %{track: t})
    else
      joined_query
    end
  end

  @spec join_album(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_album(query, select) do
    joined_query =
      query
      |> join(:inner, [track: t], l in Lilac.Album, on: t.album_id == l.id, as: :album)

    if select do
      joined_query
      |> select_merge([album: l, track: t, artist: a], %{track: %{t | album: l, artist: a}})
    else
      joined_query
    end
  end

  @spec join_artist(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_artist(query, select) do
    joined_query =
      query
      |> join(:inner, [track: t], a in Lilac.Artist, on: t.artist_id == a.id, as: :artist)

    if select do
      joined_query |> select_merge([artist: a, track: t], %{track: %{t | artist: a}})
    else
      joined_query
    end
  end
end
