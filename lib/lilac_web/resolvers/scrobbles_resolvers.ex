defmodule LilacWeb.Resolvers.Scrobbles do
  alias Lilac.Services.Scrobbles
  alias Lilac.Scrobble

  @spec list(any, %{filters: Scrobble.Filters.t()}, any) :: {:ok, any}
  def list(_root, %{filters: filters}, _info) do
    scrobbles = Scrobbles.list(filters)

    pagination =
      Lilac.Pagination.generate(Scrobbles.count(filters), Map.get(filters, :pagination))

    {:ok, %Scrobble.Page{scrobbles: scrobbles, pagination: pagination}}
  end
end
