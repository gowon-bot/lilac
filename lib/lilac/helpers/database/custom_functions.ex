defmodule Lilac.Database.CustomFunctions do
  import Ecto.Query, only: [from: 2]

  @spec albums_in(term, [Lilac.Album.queryable()]) :: term
  def albums_in(query, albums) do
    Enum.reduce(albums, query, fn album, query ->
      from l in query, or_where: l.name == ^album.name and l.artist_id == ^album.artist_id
    end)
  end

  @spec tracks_in(term, [Lilac.Track.queryable()]) :: term
  def tracks_in(query, tracks) do
    Enum.reduce(tracks, query, fn track, query ->
      from t in query,
        or_where:
          t.name == ^track.name and
            t.artist_id == ^track.artist_id and
            t.album_id == ^track.album_id
    end)
  end
end
