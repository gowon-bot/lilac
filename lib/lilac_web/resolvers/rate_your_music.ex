defmodule LilacWeb.Resolvers.RYM do
  alias Lilac.RYM

  @spec list_ratings(any, %{filters: RYM.Rating.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, any}
  def list_ratings(_root, %{filters: filters}, info) do
    ratings = Lilac.Services.Ratings.list(filters)

    {:ok, RYM.Rating.Page.generate(ratings, info, filters)}
  end
end
