defmodule Lilac.Sync.Dataset do
  import Ecto.Query, only: [from: 2]

  @spec clear(%Lilac.User{}) :: no_return()
  def clear(user) do
    Enum.each(
      [Lilac.Scrobble, Lilac.ArtistCount, Lilac.AlbumCount, Lilac.TrackCount],
      fn elem ->
        from(e in elem, where: e.user_id == ^user.id) |> Lilac.Repo.delete_all()
      end
    )
  end
end
