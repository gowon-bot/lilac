defmodule LilacWeb.Resolvers.Artists do
  alias Lilac.{Artist, ArtistCount}
  alias Lilac.Services

  @spec list(any, %{filters: Artist.Filters.t()}, Absinthe.Resolution.t()) :: {:ok, any}
  def list(_root, %{filters: filters}, info) do
    if Map.get(filters, :fetch_tags_for_missing, false) == true and
         length(Map.get(filters, :inputs, [])) > 0 do
      Services.Tags.fetch_tags_for_artists(Map.get(filters, :inputs))
    end

    artists = Services.Artists.list(filters, info)

    {:ok, Artist.Page.generate(artists, info, filters)}
  end

  @spec list_counts(any, %{filters: ArtistCount.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, ArtistCount.Page.t()}
  def list_counts(_root, %{filters: filters}, info) do
    artist_counts = Services.Artists.list_counts(filters)

    {:ok, ArtistCount.Page.generate(artist_counts, info, filters)}
  end
end
