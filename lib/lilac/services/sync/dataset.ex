defmodule Lilac.Sync.Dataset do
  import Ecto.Query, only: [from: 2]

  alias Lilac.Sync.ProgressReporter

  @spec clear(%Lilac.User{}) :: no_return()
  def clear(user) do
    Enum.each(
      [Lilac.Scrobble, Lilac.ArtistCount, Lilac.AlbumCount, Lilac.TrackCount],
      fn elem ->
        from(e in elem, where: e.user_id == ^user.id) |> Lilac.Repo.delete_all()
      end
    )
  end

  @spec insert_counts(Lilac.User.t(), [Lilac.ArtistCount.t()], [Lilac.AlbumCount.t()], [
          Lilac.TrackCount.t()
        ]) ::
          no_return()
  def insert_counts(user, artist_counts, album_counts, track_counts) do
    Lilac.Sync.ProgressReporter.set_total(
      user,
      :inserting,
      length(artist_counts) + length(album_counts) + length(track_counts)
    )

    insert_artist_counts(user, artist_counts)
    insert_album_counts(user, album_counts)
    insert_track_counts(user, track_counts)
  end

  @spec insert_artist_counts(Lilac.User.t(), [Lilac.ArtistCount.t()]) :: no_return()
  def insert_artist_counts(user, artist_counts) do
    for chunk <- Enum.chunk_every(artist_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.ArtistCount, chunk)
      ProgressReporter.capture_progress(user, :inserting, length(chunk))
    end
  end

  @spec insert_album_counts(Lilac.User.t(), [Lilac.AlbumCount.t()]) :: no_return()
  def insert_album_counts(user, album_counts) do
    for chunk <- Enum.chunk_every(album_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.AlbumCount, chunk)
      ProgressReporter.capture_progress(user, :inserting, length(chunk))
    end
  end

  @spec insert_track_counts(Lilac.User.t(), [Lilac.TrackCount.t()]) :: no_return()
  def insert_track_counts(user, track_counts) do
    for chunk <- Enum.chunk_every(track_counts, 1000) do
      Lilac.Repo.insert_all(Lilac.TrackCount, chunk)
      ProgressReporter.capture_progress(user, :inserting, length(chunk))
    end
  end
end
