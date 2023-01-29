defmodule LilacWeb.Resolvers.Albums do
  import Ecto.Query, only: [from: 2, where: 3]

  alias Lilac.{Album, AlbumCount}
  alias Lilac.Services

  def all_albums(_root, %{artist: artist_name}, _info) do
    query = from(l in Album, preload: [:artist])

    {:ok, query |> maybe_artist(artist_name) |> Lilac.Repo.all()}
  end

  def all_albums(root, _args, info) do
    all_albums(root, %{artist: nil}, info)
  end

  @spec list_counts(any, %{filters: AlbumCount.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, AlbumCount.Page.t()}
  def list_counts(_root, %{filters: filters}, info) do
    album_counts = Services.Albums.list_counts(filters, info)

    {:ok, AlbumCount.Page.generate(album_counts, info, filters)}
  end

  # Private methods

  defp maybe_artist(query, nil), do: query

  defp maybe_artist(query, artist_name) do
    artist = Lilac.Repo.get_by(Lilac.Artist, name: artist_name)

    unless artist == nil,
      do: query |> where([l], l.artist_id == ^artist.id),
      # sketchy as fuck lol
      else: query |> where([], 1 == 0)
  end
end
