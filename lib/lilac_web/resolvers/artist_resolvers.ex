defmodule LilacWeb.Resolvers.Artists do
  alias Lilac.Services.Artists
  alias Lilac.Artist

  @spec list(any, %{filters: Artist.Filters.t()}, any) :: {:ok, any}
  def list(_root, %{filters: filters}, _info) do
    artists = Artists.list(filters)

    pagination = Lilac.Pagination.generate(Artists.count(filters), Map.get(filters, :pagination))

    {:ok, %Artist.Page{artists: artists, pagination: pagination}}
  end
end
