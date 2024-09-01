defmodule LilacWeb.Resolvers.RYM do
  alias Lilac.RYM

  @spec list_ratings(any, %{filters: RYM.Rating.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, any}
  def list_ratings(_root, %{filters: filters}, info) do
    ratings = Lilac.Services.Ratings.list(filters)

    {:ok, RYM.Rating.Page.generate(ratings, info, filters)}
  end

  @spec rate_your_music_artist(any, %{keywords: String.t()}, any) :: {:ok, RYM.Artist.t()}
  def rate_your_music_artist(_root, %{keywords: keywords}, _info) do
    {:ok, Lilac.Services.Ratings.get_artist(keywords)}
  end

  @spec list_artist_ratings(any, %{filters: RYM.Rating.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, RYM.Artist.Rating.Page.t()}
  def list_artist_ratings(_root, %{filters: filters}, info) do
    ratings = Lilac.Services.Ratings.list_artist_ratings(filters)

    {:ok, RYM.Artist.Rating.Page.generate(ratings, info, filters)}
  end

  # @spec stats(any, %{filters: RYM.Stats.Filters.t()}) :: {:ok, RYM.Stats.t()}
  # def stats(_root, %{filters: filters}) do
  #   {:ok, Lilac.Services.Ratings.stats(filters)}
  # end
end
