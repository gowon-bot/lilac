defmodule Lilac.Services.LastFM do
  alias Lilac.Services.LastFMAPI
  alias Lilac.Services.LastFMAPI.Types

  # Recent tracks
  def nowplaying(username) do
    recent_tracks(%Types.RecentTracksParams{username: username, limit: 1})
  end

  def recent_tracks(%Types.RecentTracksParams{} = params) do
    LastFMAPI.get(
      "method=user.getRecentTracks&user=#{params.username}&limit=#{params.limit}&page=#{params.page}"
    )
  end
end
