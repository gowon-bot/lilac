defmodule Lilac.Services.Scrobbles do
  import Ecto.Query, only: [from: 2, from: 1, join: 5, select_merge: 3, select: 3]

  alias Lilac.InputParser
  alias Lilac.Scrobble
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  @spec list(Scrobble.Filters.t(), Absinthe.Resolution.t()) :: [Scrobble.t()]
  def list(filters, info) do
    from(s in Lilac.Scrobble,
      order_by: [desc: s.scrobbled_at],
      select_merge: s
    )
    |> generate_joins(filters, info)
    |> parse_scrobble_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Scrobble.Filters.t()) :: integer
  def count(filters) do
    from(s in Scrobble)
    |> generate_joins(filters, %Absinthe.Resolution{}, false)
    |> parse_scrobble_filters(filters |> Map.put(:pagination, nil))
    |> select([], count())
    |> Lilac.Repo.one()
  end

  @spec parse_scrobble_filters(Ecto.Query.t(), Scrobble.Filters.t()) :: Ecto.Query.t()
  defp parse_scrobble_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_input(Map.get(filters, :user))
    |> InputParser.Artist.maybe_artist_input(Map.get(filters, :artist))
    |> InputParser.Album.maybe_album_input(Map.get(filters, :album))
    |> InputParser.Track.maybe_track_input(Map.get(filters, :track))
  end

  @spec generate_joins(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          Absinthe.Resolution.t(),
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins(query, filters, info, select \\ true) do
    query
    |> chained_maybe_join_track(filters, info, select)
    |> maybe_join_user(filters, info, select)
  end

  @spec chained_maybe_join_track(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          Absinthe.Resolution.t(),
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_track(query, filters, info, select) do
    if Map.has_key?(filters, :track) || Introspection.has_field?(info, Fields.Scrobble.track()) do
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
          Absinthe.Resolution.t(),
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_album(query, filters, info, select) do
    if Map.has_key?(filters, :album) || Introspection.has_field?(info, Fields.Scrobble.album()) do
      query
      |> join_album(select)
      |> join_artist(select)
    else
      query |> maybe_join_artist(filters, info, select)
    end
  end

  @spec maybe_join_artist(Ecto.Query.t(), Scrobble.Filters.t(), Absinthe.Resolution.t(), boolean) ::
          Ecto.Query.t()
  defp maybe_join_artist(query, filters, info, select) do
    if Map.has_key?(filters, :artist) ||
         Introspection.has_field?(info, Fields.Scrobble.artist()) do
      query
      |> join_artist(select)
    else
      query
    end
  end

  @spec maybe_join_user(Ecto.Query.t(), Scrobble.Filters.t(), Absinthe.Resolution.t(), boolean) ::
          Ecto.Query.t()
  defp maybe_join_user(query, filters, info, select) do
    if Map.has_key?(filters, :user) ||
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
