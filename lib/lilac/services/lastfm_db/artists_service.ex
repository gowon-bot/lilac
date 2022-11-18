defmodule Lilac.Services.Artists do
  import Ecto.Query, only: [from: 2, join: 5, preload: 3, where: 3]

  alias Lilac.InputParser
  alias Lilac.{Artist, ArtistCount}

  @spec list(Artist.Filters.t()) :: [Artist.t()]
  def list(filters) do
    from(a in Artist, as: :artist)
    |> join(:left, [artist: a], t in assoc(a, :tags), as: :tag)
    |> preload([tag: t], tags: t)
    |> parse_artist_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec list_counts(ArtistCount.Filters.t()) :: [ArtistCount.t()]
  def list_counts(filters) do
    from(ac in ArtistCount,
      as: :artist_count,
      order_by: [desc: :playcount],
      preload: :artist
    )
    |> join(:left, [artist_count: ac], u in assoc(ac, :user), as: :user)
    |> maybe_in_artist_list(filters)
    |> parse_artist_count_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count_counts(Artist.Filters.t()) :: integer
  def count_counts(filters) do
    from(ac in ArtistCount, as: :artist_count, select: count(ac.id))
    |> join(:left, [artist_count: ac], u in assoc(ac, :user), as: :user)
    |> maybe_in_artist_list(filters)
    |> parse_artist_count_filters(filters)
    |> Lilac.Repo.one()
  end

  @spec count(Artist.Filters.t()) :: integer
  def count(filters) do
    from(a in Artist, as: :artist, select: count())
    |> parse_artist_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec parse_artist_filters(Ecto.Query.t(), Artist.Filters.t()) :: Ecto.Query.t()
  defp parse_artist_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Artist.maybe_artist_inputs(Map.get(filters, :inputs))
    |> InputParser.Artist.maybe_tag_inputs(
      Map.get(filters, :tags),
      Map.get(filters, :match_tags_exactly, false)
    )
  end

  @spec parse_artist_count_filters(Ecto.Query.t(), ArtistCount.Filters.t()) :: Ecto.Query.t()
  defp parse_artist_count_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_inputs(Map.get(filters, :users))
  end

  @spec maybe_in_artist_list(Ecto.Query.t(), ArtistCount.Filters.t()) :: [integer]
  defp maybe_in_artist_list(query, filters) do
    if(Map.has_key?(filters, :inputs) || Map.has_key?(filters, :tags)) do
      artist_ids = list(filters |> Map.put(:pagination, nil)) |> Enum.map(fn a -> a.id end)

      query |> where([artist_count: ac], ac.artist_id in ^artist_ids)
    else
      query
    end
  end
end
