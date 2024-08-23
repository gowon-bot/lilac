defmodule Lilac.Sync.Dataset do
  import Ecto.Query, only: [from: 2]

  alias Ecto.Multi
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

    insert_counts(user, artist_counts, Lilac.ArtistCount)
    insert_counts(user, album_counts, Lilac.AlbumCount)
    insert_counts(user, track_counts, Lilac.TrackCount)
  end

  @spec upsert_counts(Lilac.User.t(), [Lilac.ArtistCount.t()], [Lilac.AlbumCount.t()], [
          Lilac.TrackCount.t()
        ]) ::
          no_return()
  def upsert_counts(user, artist_counts, album_counts, track_counts) do
    Lilac.Sync.ProgressReporter.set_total(
      user,
      :inserting,
      length(artist_counts) + length(album_counts) + length(track_counts)
    )

    upsert_artist_counts(user, artist_counts)
    upsert_album_counts(user, album_counts)
    upsert_track_counts(user, track_counts)
  end

  @spec insert_counts(Lilac.User.t(), [map], atom) :: no_return()
  defp insert_counts(user, counts, entity) do
    for chunk <- Enum.chunk_every(counts, 1000) do
      Lilac.Repo.insert_all(entity, chunk)
      ProgressReporter.capture_progress(user, :inserting, length(chunk))
    end
  end

  @spec update_counts(Lilac.User.t(), [Ecto.Changeset.t()]) :: no_return()
  defp update_counts(user, counts) do
    for chunk <- Enum.chunk_every(counts, 1000) do
      chunk
      |> Enum.with_index()
      |> Enum.reduce(Multi.new(), fn {changeset, idx}, multi ->
        Multi.update(multi, idx, changeset)
      end)
      |> Lilac.Repo.transaction()

      ProgressReporter.capture_progress(user, :inserting, length(chunk))
    end
  end

  # Upserts

  @spec upsert_artist_counts(Lilac.User.t(), [Lilac.ArtistCount.t()]) :: no_return()
  defp upsert_artist_counts(user, artist_counts) do
    artist_ids = artist_counts |> Enum.map(fn ac -> ac.artist_id end)

    from(ac in Lilac.ArtistCount, where: ac.user_id == ^user.id and ac.artist_id in ^artist_ids)
    |> Lilac.Repo.all()
    |> generate_upserts(artist_counts, :artist_id)
    |> insert_and_update(user, Lilac.ArtistCount)
  end

  @spec upsert_album_counts(Lilac.User.t(), [Lilac.AlbumCount.t()]) :: no_return()
  defp upsert_album_counts(user, album_counts) do
    album_ids = album_counts |> Enum.map(fn lc -> lc.album_id end)

    from(lc in Lilac.AlbumCount, where: lc.user_id == ^user.id and lc.album_id in ^album_ids)
    |> Lilac.Repo.all()
    |> generate_upserts(album_counts, :album_id)
    |> insert_and_update(user, Lilac.AlbumCount)
  end

  @spec upsert_track_counts(Lilac.User.t(), [Lilac.TrackCount.t()]) :: no_return()
  defp upsert_track_counts(user, track_counts) do
    track_ids = track_counts |> Enum.map(fn tc -> tc.track_id end)

    from(tc in Lilac.TrackCount, where: tc.user_id == ^user.id and tc.track_id in ^track_ids)
    |> Lilac.Repo.all()
    |> generate_upserts(track_counts, :track_id)
    |> insert_and_update(user, Lilac.TrackCount)
  end

  @spec generate_upserts([struct], [map], atom) :: {[Ecto.Changeset.t()], [map]}
  defp generate_upserts(persisted_counts, unpersisted_counts, comparison_key) do
    Enum.reduce(unpersisted_counts, {[], []}, fn ac, {updates, inserts} ->
      matching_count =
        Enum.find(persisted_counts, fn persisted_count ->
          Map.get(persisted_count, comparison_key) == Map.get(ac, comparison_key)
        end)

      case matching_count do
        nil -> {updates, inserts ++ [ac]}
        count -> {updates ++ [create_changeset(count, ac)], inserts}
      end
    end)
  end

  defp insert_and_update({updates, inserts}, user, entity) do
    insert_counts(user, inserts, entity)
    update_counts(user, updates)
  end

  @spec create_changeset(struct, map) :: Ecto.Changeset.t()
  defp create_changeset(existing_count, new_count) do
    Ecto.Changeset.change(existing_count,
      playcount: existing_count.playcount + new_count.playcount,
      last_scrobbled: new_count.last_scrobbled
    )
  end
end
