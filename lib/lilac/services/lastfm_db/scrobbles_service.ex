defmodule Lilac.Services.Scrobbles do
  import Ecto.Query, only: [from: 2]

  alias Lilac.InputParser

  @spec list(Lilac.Scrobble.Filters.t()) :: [Lilac.Scrobble.t()]
  def list(filters) do
    from(s in Lilac.Scrobble,
      order_by: [desc: s.scrobbled_at],
      # User
      join: u in Lilac.User,
      as: :user,
      on: s.user_id == u.id,
      # Artist
      join: a in Lilac.Artist,
      as: :artist,
      on: s.artist_id == a.id,
      # Album
      join: l in Lilac.Album,
      as: :album,
      on: s.album_id == l.id,
      # Track
      join: t in Lilac.Track,
      as: :track,
      on: s.track_id == t.id,
      # Select
      select: %{s | user: u, artist: a, album: l, track: t}
    )
    |> parse_scrobble_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Lilac.Scrobble.Filters.t()) :: integer
  def count(filters) do
    from(s in Lilac.Scrobble,
      select: count(),
      # User
      join: u in Lilac.User,
      as: :user,
      on: s.user_id == u.id,
      # Artist
      join: a in Lilac.Artist,
      as: :artist,
      on: s.artist_id == a.id,
      # Album
      join: l in Lilac.Album,
      as: :album,
      on: s.album_id == l.id,
      # Track
      join: t in Lilac.Track,
      as: :track,
      on: s.track_id == t.id
    )
    |> parse_scrobble_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec parse_scrobble_filters(Ecto.Query.t(), Lilac.Scrobble.Filters.t()) :: Ecto.Query.t()
  defp parse_scrobble_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_input(Map.get(filters, :user))
    |> InputParser.Artist.maybe_artist_input(Map.get(filters, :artist))
    |> InputParser.Album.maybe_album_input(Map.get(filters, :album))
    |> InputParser.Track.maybe_track_input(Map.get(filters, :track))
  end
end
