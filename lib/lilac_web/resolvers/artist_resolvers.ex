defmodule LilacWeb.Resolvers.Artists do
  alias Lilac.Services.Artists

  alias Lilac.Artist

  @spec list(any, %{filters: Artist.Filters.t()}, any) :: {:ok, any}
  def list(_root, %{filters: filters}, _info) do
    if Map.get(filters, :fetch_tags_for_missing, false) == true and
         length(Map.get(filters, :inputs, [])) > 0 do
      Lilac.Services.Tags.fetch_tags_for_artists(Map.get(filters, :inputs))
    end

    artists = Artists.list(filters)

    {:ok,
     %Artist.Page{
       artists: artists,
       pagination:
         Lilac.Pagination.generate(Artists.count(filters), Map.get(filters, :pagination))
     }}
  end
end
