defmodule LilacWeb.Resolvers.Artists do
  alias Lilac.{Artist, ArtistCount}
  alias Lilac.Services

  @spec list(any, %{filters: Artist.Filters.t()}, any) :: {:ok, any}
  def list(_root, %{filters: filters}, _info) do
    if Map.get(filters, :fetch_tags_for_missing, false) == true and
         length(Map.get(filters, :inputs, [])) > 0 do
      Services.Tags.fetch_tags_for_artists(Map.get(filters, :inputs))
    end

    artists = Services.Artists.list(filters)

    {:ok,
     %Artist.Page{
       artists: artists,
       pagination:
         Lilac.Pagination.generate(Services.Artists.count(filters), Map.get(filters, :pagination))
     }}
  end

  @spec list_counts(any, %{filters: Artist.Filters.t()}, any) :: {:ok, any}
  def list_counts(_root, %{filters: filters}, _info) do
    artist_counts = Services.Artists.list_counts(filters)

    {:ok,
     %ArtistCount.Page{
       artist_counts: artist_counts,
       pagination:
         Lilac.Pagination.generate(
           Services.Artists.count_counts(filters),
           Map.get(filters, :pagination)
         )
     }}
  end
end
