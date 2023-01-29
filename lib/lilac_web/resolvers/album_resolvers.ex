defmodule LilacWeb.Resolvers.Albums do
  alias Lilac.{Album, AlbumCount}
  alias Lilac.Services

  @spec list(any, %{filters: Album.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, Album.Page.t()}
  def list(_root, %{filters: filters}, info) do
    albums = Services.Albums.list(filters, info)

    {:ok, Album.Page.generate(albums, info, filters)}
  end

  @spec list_counts(any, %{filters: AlbumCount.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, AlbumCount.Page.t()}
  def list_counts(_root, %{filters: filters}, info) do
    album_counts = Services.Albums.list_counts(filters, info)

    {:ok, AlbumCount.Page.generate(album_counts, info, filters)}
  end

  # Private methods
end
