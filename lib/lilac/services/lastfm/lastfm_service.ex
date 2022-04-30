defmodule Lilac.LastFM do
  alias Lilac.LastFM.API
  alias Lilac.LastFM.API.Params
  alias __MODULE__.Responses

  # Recent tracks
  def nowplaying(username) do
    recent_tracks(%Params.RecentTracks{username: username, limit: 1})
  end

  @spec recent_tracks(Params.RecentTracks.t()) ::
          {:ok, %Responses.RecentTracks{}} | {:error, struct}
  def recent_tracks(%Params.RecentTracks{} = params) do
    params
    |> API.Params.build("user.getRecentTracks")
    |> API.get()
    |> API.handle_response()
  end
end
