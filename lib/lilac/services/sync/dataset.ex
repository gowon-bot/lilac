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

  @spec insert_counts([Lilac.ArtistCount.t()], [Lilac.AlbumCount.t()], [Lilac.TrackCount.t()]) ::
          no_return()
  def insert_counts(artist_counts, album_counts, track_counts) do
    insert_artist_counts(artist_counts)
    insert_album_counts(album_counts)
    insert_track_counts(track_counts)
  end

  @spec insert_artist_counts([Lilac.ArtistCount.t()]) :: no_return()
  def insert_artist_counts(artist_counts) do
    for chunk <- Enum.chunk_every(artist_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.ArtistCount, chunk)
    end
  end

  @spec insert_album_counts([Lilac.AlbumCount.t()]) :: no_return()
  def insert_album_counts(album_counts) do
    for chunk <- Enum.chunk_every(album_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.AlbumCount, chunk)
    end
  end

  @spec insert_track_counts([Lilac.TrackCount.t()]) :: no_return()
  def insert_track_counts(track_counts) do
    for chunk <- Enum.chunk_every(track_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.TrackCount, chunk)
    end
  end
end
