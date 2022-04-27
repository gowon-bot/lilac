defmodule Lilac.Services.Counting do
  import Ecto.Query, only: [from: 2]
  alias Ecto.Multi

  alias Lilac.CountingHelpers

  @spec upsert_artist_counts(%Lilac.User{}, map) :: no_return
  def upsert_artist_counts(user, counting_map) do
    artist_ids = Enum.map(counting_map, fn {id, _count} -> id end)

    %{inserts: inserts, updates: updates} =
      from(ac in Lilac.ArtistCount, where: ac.user_id == ^user.id and ac.artist_id in ^artist_ids)
      |> Lilac.Repo.all()
      |> extract_upserts(counting_map, :artist_id, user)

    insert_counts(Lilac.ArtistCount, inserts)
    update_counts(updates)
  end

  @spec upsert_album_counts(%Lilac.User{}, map) :: no_return
  def upsert_album_counts(user, counting_map) do
    album_ids = Enum.map(counting_map, fn {id, _count} -> id end)

    %{inserts: inserts, updates: updates} =
      from(ac in Lilac.AlbumCount, where: ac.user_id == ^user.id and ac.album_id in ^album_ids)
      |> Lilac.Repo.all()
      |> extract_upserts(counting_map, :album_id, user)

    insert_counts(Lilac.AlbumCount, inserts)
    update_counts(updates)
  end

  @spec upsert_track_counts(%Lilac.User{}, map) :: no_return
  def upsert_track_counts(user, counting_map) do
    track_ids = Enum.map(counting_map, fn {id, _count} -> id end)

    %{inserts: inserts, updates: updates} =
      from(tc in Lilac.TrackCount, where: tc.user_id == ^user.id and tc.track_id in ^track_ids)
      |> Lilac.Repo.all()
      |> extract_upserts(counting_map, :track_id, user)

    insert_counts(Lilac.TrackCount, inserts)
    update_counts(updates)
  end

  # Helpers

  @spec extract_upserts([CountingHelpers.any_count()], map, atom, %Lilac.User{}) :: %{
          inserts: [map],
          updates: [Ecto.Changeset]
        }
  def extract_upserts(counts, counting_map, id_key, user) do
    Enum.reduce(counting_map, %{inserts: [], updates: []}, fn {id, playcount}, acc ->
      existing_count = Enum.find(counts, nil, fn count -> Map.get(count, id_key) == id end)

      if existing_count != nil do
        Map.put(
          acc,
          :updates,
          acc.updates ++ [CountingHelpers.changeset(existing_count, playcount)]
        )
      else
        new_count = %{user_id: user.id, playcount: playcount} |> Map.put(id_key, id)

        Map.put(
          acc,
          :inserts,
          acc.inserts ++ [new_count]
        )
      end
    end)
  end

  # Artist counts
  @spec insert_counts(term, [map]) :: no_return()
  def insert_counts(entity, insertables) do
    Lilac.Repo.insert_all(entity, insertables)
  end

  @spec update_counts([Ecto.Changeset]) :: no_return()
  def update_counts(changesets) do
    Enum.with_index(changesets)
    |> Enum.reduce(Multi.new(), fn {changeset, index}, multi ->
      Multi.update(multi, index, changeset)
    end)
    |> Lilac.Repo.transaction()
  end
end
