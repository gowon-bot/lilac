defmodule Lilac.Services.Artists do
  import Ecto.Query, only: [from: 2, join: 5]

  alias Lilac.{InputParser, Joiner}
  alias Lilac.{Artist, ArtistCount}

  @spec list(Artist.Filters.t(), %Absinthe.Resolution{}) :: [Artist.t()]
  def list(filters, info) do
    from(a in Artist, as: :artist)
    |> Joiner.Artist.maybe_join_tags(filters, info, true)
    |> parse_artist_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Artist.Filters.t()) :: integer
  def count(filters) do
    from(a in Artist, as: :artist, select: count())
    |> Joiner.Artist.maybe_join_tags(filters, %Absinthe.Resolution{}, false)
    |> parse_artist_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec list_counts(ArtistCount.Filters.t()) :: [ArtistCount.t()]
  def list_counts(filters) do
    from(ac in ArtistCount,
      as: :artist_count,
      order_by: [desc: :playcount],
      preload: :artist
    )
    |> join(:left, [artist_count: ac], u in assoc(ac, :user), as: :user)
    |> parse_artist_count_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count_counts(Artist.Filters.t()) :: integer
  def count_counts(filters) do
    from(ac in ArtistCount, as: :artist_count, select: count(ac.id))
    |> join(:left, [artist_count: ac], u in assoc(ac, :user), as: :user)
    |> parse_artist_count_filters(filters)
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
    |> InputParser.Artist.maybe_in_artist_list(Map.get(filters, :inputs), Map.get(filters, :tags))
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_inputs(Map.get(filters, :users))
  end
end
