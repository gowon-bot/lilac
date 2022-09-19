defmodule Lilac.Services.WhoKnows do
  import Ecto.Query, only: [from: 2]

  alias Lilac.WhoKnows.{
    WhoKnowsArtistResponse,
    WhoKnowsArtistRank,
    WhoKnowsAlbumResponse,
    WhoKnowsAlbumRank,
    WhoKnowsTrackResponse,
    WhoKnowsTrackRank
  }

  alias Lilac.InputParser

  @spec who_knows_artist(Lilac.Artist.t(), Lilac.WhoKnows.Input.t()) :: WhoKnowsArtistResponse.t()
  def who_knows_artist(artist, settings) do
    if !artist do
      %WhoKnowsArtistResponse{artist: artist, rows: []}
    else
      rows =
        from(ac in Lilac.ArtistCount,
          join: u in Lilac.User,
          on: ac.user_id == u.id,
          where: ac.artist_id == ^artist.id,
          order_by: [desc: ac.playcount, desc: u.username],
          preload: [:user]
        )
        |> parse_who_knows_settings(settings)
        |> Lilac.Repo.all()

      %WhoKnowsArtistResponse{artist: artist, rows: rows}
    end
  end

  @spec who_knows_artist_rank(Lilac.Artist.t(), Lilac.User.t(), Lilac.WhoKnows.Input.t()) ::
          WhoKnowsArtistRank.t()
  def who_knows_artist_rank(artist, user, settings) do
    if !artist do
      %WhoKnowsArtistRank{artist: artist}
    else
      rows = who_knows_artist(artist, settings).rows

      user_row_idx = Enum.find_index(rows, fn r -> r.user_id == user.id end) || -1

      %WhoKnowsArtistRank{
        artist: artist,
        rank: user_row_idx + 1,
        playcount: if(user_row_idx != -1, do: Enum.at(rows, user_row_idx).playcount, else: 0),
        total_listeners: length(rows),
        above:
          if(user_row_idx != 0 and user_row_idx != -1,
            do: Enum.at(rows, user_row_idx - 1),
            else: nil
          ),
        below:
          if(user_row_idx < length(rows) - 1 and user_row_idx != -1,
            do: Enum.at(rows, user_row_idx + 1),
            else: nil
          )
      }
    end
  end

  @spec who_knows_album(Lilac.Album.t(), Lilac.WhoKnows.Input.t()) :: WhoKnowsAlbumResponse.t()
  def who_knows_album(album, settings) do
    if !album do
      %WhoKnowsAlbumResponse{album: album, rows: []}
    else
      rows =
        from(ac in Lilac.AlbumCount,
          join: u in Lilac.User,
          on: ac.user_id == u.id,
          where: ac.album_id == ^album.id,
          order_by: [desc: ac.playcount, desc: u.username],
          preload: [:user]
        )
        |> parse_who_knows_settings(settings)
        |> Lilac.Repo.all()

      %WhoKnowsAlbumResponse{album: album, rows: rows}
    end
  end

  @spec who_knows_album_rank(Lilac.Album.t(), Lilac.User.t(), Lilac.WhoKnows.Input.t()) ::
          WhoKnowsAlbumRank.t()
  def who_knows_album_rank(album, user, settings) do
    if !album do
      %WhoKnowsAlbumRank{album: album}
    else
      rows = who_knows_album(album, settings).rows

      user_row_idx = Enum.find_index(rows, fn r -> r.user_id == user.id end)

      %WhoKnowsAlbumRank{
        album: album,
        rank: user_row_idx + 1,
        playcount: if(user_row_idx != -1, do: Enum.at(rows, user_row_idx).playcount, else: 0),
        total_listeners: length(rows),
        above: if(user_row_idx != 0, do: Enum.at(rows, user_row_idx - 1), else: nil),
        below: if(user_row_idx < length(rows) - 1, do: Enum.at(rows, user_row_idx + 1), else: nil)
      }
    end
  end

  @spec who_knows_track(Lilac.Track.Ambiguous.t(), Lilac.WhoKnows.Input.t()) ::
          %WhoKnowsTrackResponse{}
  def who_knows_track(ambiguous_track, settings) do
    if !ambiguous_track do
      %WhoKnowsTrackResponse{track: ambiguous_track, rows: []}
    else
      rows =
        from(tc in Lilac.TrackCount,
          join: u in Lilac.User,
          on: tc.user_id == u.id,
          where: tc.track_id in ^Enum.map(ambiguous_track.tracks, fn t -> t.id end),
          order_by: [desc: sum(tc.playcount), desc: u.username],
          group_by: [u.id, u.username],
          select: %{playcount: sum(tc.playcount), user: u}
        )
        |> parse_who_knows_settings(settings)
        |> Lilac.Repo.all()

      %WhoKnowsTrackResponse{track: ambiguous_track, rows: rows}
    end
  end

  @spec who_knows_track_rank(Lilac.Track.Ambiguous.t(), Lilac.User.t(), Lilac.WhoKnows.Input.t()) ::
          WhoKnowsTrackRank.t()
  def who_knows_track_rank(track, user, settings) do
    if !track do
      %WhoKnowsTrackRank{track: track}
    else
      rows = who_knows_track(track, settings).rows

      user_row_idx = Enum.find_index(rows, fn r -> r.user.id == user.id end)

      %WhoKnowsTrackRank{
        track: track,
        rank: user_row_idx + 1,
        playcount: if(user_row_idx != -1, do: Enum.at(rows, user_row_idx).playcount, else: 0),
        total_listeners: length(rows),
        above: if(user_row_idx != 0, do: Enum.at(rows, user_row_idx - 1), else: nil),
        below: if(user_row_idx < length(rows) - 1, do: Enum.at(rows, user_row_idx + 1), else: nil)
      }
    end
  end

  @spec parse_who_knows_settings(Ecto.Query.t(), %Lilac.WhoKnows.Input{}) :: Ecto.Query.t()
  defp parse_who_knows_settings(query, settings) do
    query
    |> InputParser.WhoKnows.maybe_guild_id(Map.get(settings, :guild_id))
    |> InputParser.WhoKnows.maybe_user_ids(Map.get(settings, :user_ids))
    |> InputParser.maybe_limit(Map.get(settings, :limit))
  end
end
