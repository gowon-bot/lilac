defmodule Lilac.Services.Albums do
  import Ecto.Query, only: [from: 2, select_merge: 3]

  alias Lilac.{InputParser, Joiner}
  alias Lilac.{Album, AlbumCount}

  @spec list(Album.Filters.t(), %Absinthe.Resolution{}) :: [Album.t()]
  def list(filters, info) do
    from(l in Album, as: :album)
    |> generate_joins(filters, info)
    |> parse_album_filters(filters)
    |> select_merge([album: l], %{l | name: coalesce(l.name, "(no album)")})
    |> Lilac.Repo.all()
  end

  @spec count(Album.Filters.t()) :: integer
  def count(filters) do
    from(a in Album, as: :album, select: count())
    |> parse_album_filters(filters |> Map.put(:pagination, nil))
    |> generate_joins(filters, %Absinthe.Resolution{})
    |> Lilac.Repo.one()
  end

  @spec list_counts(AlbumCount.Filters.t(), Absinthe.Resolution.t()) :: [AlbumCount.t()]
  def list_counts(filters, info) do
    from(ac in AlbumCount,
      as: :album_count,
      order_by: [desc: :playcount]
    )
    |> generate_joins_for_counts(filters, info)
    |> parse_album_count_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count_counts(AlbumCount.Filters.t()) :: integer
  def count_counts(filters) do
    from(ac in AlbumCount, as: :album_count, select: count(ac.id))
    |> generate_joins_for_counts(filters, %Absinthe.Resolution{}, false)
    |> parse_album_count_filters(filters)
    |> Lilac.Repo.one()
  end

  @spec parse_album_count_filters(Ecto.Query.t(), AlbumCount.Filters.t()) :: Ecto.Query.t()
  defp parse_album_count_filters(query, filters) do
    query
    |> parse_album_filters(filters)
    |> InputParser.User.maybe_user_inputs(Map.get(filters, :users))
  end

  @spec parse_album_filters(Ecto.Query.t(), Album.Filters.t()) :: Ecto.Query.t()
  defp parse_album_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Album.maybe_album_input(Map.get(filters, :album))
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
    |> Joiner.Album.maybe_join_artist(filters, info, select)
  end

  @spec generate_joins_for_counts(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins_for_counts(query, filters, info, select \\ true) do
    query
    |> Joiner.AlbumCount.chained_maybe_join_album_artist(filters, info, select)
    |> Joiner.AlbumCount.maybe_join_user(filters, info, select)
  end
end
