defmodule Lilac.Services.Artists do
  import Ecto.Query, only: [from: 2, join: 5, preload: 3]

  alias Lilac.InputParser
  alias Lilac.Artist

  @spec list(Artist.Filters.t()) :: [Artist.t()]
  def list(filters) do
    from(a in Artist, as: :artist)
    |> join(:left, [artist: a], t in assoc(a, :tags), as: :tag)
    |> preload([tag: t], tags: t)
    |> parse_artist_filters(filters)
    |> Lilac.Repo.all()
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
end
