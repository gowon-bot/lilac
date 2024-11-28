defmodule LilacWeb.Resolvers.RYM do
  alias Lilac.RYM
  alias Lilac.Ratings
  alias Lilac.Services.Auth

  @spec list_ratings(any, %{filters: RYM.Rating.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, any}
  def list_ratings(_root, %{filters: filters}, info) do
    ratings = Ratings.list(filters)

    {:ok, RYM.Rating.Page.generate(ratings, info, filters)}
  end

  @spec rate_your_music_artist(any, %{keywords: String.t()}, any) :: {:ok, RYM.Artist.t()}
  def rate_your_music_artist(_root, %{keywords: keywords}, _info) do
    {:ok, Ratings.get_artist(keywords)}
  end

  @spec list_artist_ratings(any, %{filters: RYM.Rating.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, RYM.Artist.Rating.Page.t()}
  def list_artist_ratings(_root, %{filters: filters}, info) do
    ratings = Ratings.list_artist_ratings(filters)

    {:ok, RYM.Artist.Rating.Page.generate(ratings, info, filters)}
  end

  def import_ratings(_root, %{user: user_input, ratings_csv: csv}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Ratings.Import.Importer.import(user, csv)
  end
end
