defmodule Lilac.Services.Artists do
  import Ecto.Query, only: [from: 2]

  alias Lilac.InputParser

  @spec list(Lilac.Artist.Filters.t()) :: [Lilac.Artist.t()]
  def list(filters) do
    from(a in Lilac.Artist, as: :artist)
    |> parse_artist_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Lilac.Artist.Filters.t()) :: integer
  def count(filters) do
    from(a in Lilac.Artist, as: :artist, select: count())
    |> parse_artist_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec parse_artist_filters(Ecto.Query.t(), Lilac.Artist.Filters.t()) :: Ecto.Query.t()
  defp parse_artist_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Artist.maybe_artist_inputs(Map.get(filters, :inputs))
    |> InputParser.Tag.maybe_tag_inputs(
      Map.get(filters, :tags),
      Map.get(filters, :match_tags_exactly, false)
    )
  end
end
