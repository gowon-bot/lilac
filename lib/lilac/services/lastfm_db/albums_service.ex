defmodule Lilac.Services.Albums do
  import Ecto.Query, only: [from: 2, join: 5, select_merge: 3]

  alias Lilac.InputParser
  alias Lilac.AlbumCount
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  @spec list_counts(AlbumCount.Filters.t(), Absinthe.Resolution.t()) :: [AlbumCount.t()]
  def list_counts(filters, info) do
    from(ac in AlbumCount,
      as: :album_count,
      order_by: [desc: :playcount]
    )
    |> generate_joins(filters, info)
    |> parse_album_count_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count_counts(AlbumCount.Filters.t()) :: integer
  def count_counts(filters) do
    from(ac in AlbumCount, as: :album_count, select: count(ac.id))
    |> generate_joins(filters, %Absinthe.Resolution{}, false)
    |> parse_album_count_filters(filters)
    |> Lilac.Repo.one()
  end

  @spec parse_album_count_filters(Ecto.Query.t(), AlbumCount.Filters.t()) :: Ecto.Query.t()
  defp parse_album_count_filters(query, filters) do
    query
    |> InputParser.Album.maybe_album_input(Map.get(filters, :album))
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_inputs(Map.get(filters, :users))
  end

  @spec generate_joins(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins(query, filters, info, select \\ true) do
    query
    |> chained_maybe_join_album_artist(filters, info, select)
    |> maybe_join_user(filters, info, select)
  end

  @spec chained_maybe_join_album_artist(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp chained_maybe_join_album_artist(query, filters, info, select) do
    if (is_map(Map.get(filters, :album)) && Map.has_key?(filters.album, :artist)) ||
         Introspection.has_field?(info, Fields.Album.Count.album_artist()) do
      query
      |> join_album_artist(select)
    else
      query |> maybe_join_album(filters, info, select)
    end
  end

  @spec maybe_join_album(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp maybe_join_album(query, filters, info, select) do
    if Map.has_key?(filters, :album) ||
         Introspection.has_field?(info, Fields.Album.Count.album_artist()) do
      query
      |> join_album(select)
    else
      query
    end
  end

  @spec maybe_join_user(Ecto.Query.t(), AlbumCount.Filters.t(), %Absinthe.Resolution{}, boolean) ::
          Ecto.Query.t()
  defp maybe_join_user(query, filters, info, select) do
    if Map.has_key?(filters, :users) ||
         Introspection.has_field?(info, Fields.Album.Count.user()) do
      query
      |> join_user(select)
    else
      query
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
end
