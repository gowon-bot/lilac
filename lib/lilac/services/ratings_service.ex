defmodule Lilac.Services.Ratings do
  import Ecto.Query, only: [from: 2]

  alias Lilac.RYM.Rating
  alias Lilac.{Joiner, InputParser}

  @spec list(RYM.Rating.Filters.t()) :: [RYM.Rating.t()]
  def list(filters) do
    from(r in Rating, as: :rating)
    |> Joiner.Rating.join_rym_album(true)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_rating_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(RYM.Rating.Filters.t()) :: integer
  def count(filters) do
    from(r in Rating, as: :rating, select: count())
    |> Joiner.Rating.join_rym_album(false)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_rating_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec parse_rating_filters(Ecto.Query.t(), Rating.Filters.t()) :: Ecto.Query.t()
  defp parse_rating_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_input(Map.get(filters, :user))
    |> InputParser.Rating.maybe_album_input(Map.get(filters, :album))
    |> InputParser.Rating.maybe_rating(Map.get(filters, :rating))
  end
end
