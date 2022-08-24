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
    |> API.handle_response(&Responses.RecentTracks.from_map/1)
  end

  @spec artist_info(Params.ArtistInfo.t()) :: {:ok, %Responses.ArtistInfo{}} | {:error, struct}
  def artist_info(params) do
    params
    |> API.Params.build("artist.getInfo")
    |> API.get()
    |> API.handle_response(&Responses.ArtistInfo.from_map/1)
  end

  @spec get_artist(binary) :: {:error, struct} | {:ok, Lilac.Artist.t()}
  def get_artist(artist_name) do
    artist = Lilac.Repo.get_by(Lilac.Artist, %{name: artist_name})

    if !is_nil(artist) do
      {:ok, artist}
    else
      unknown_artist_name = handle_unknown_artist(artist_name)

      if !is_nil(unknown_artist_name) do
        case Lilac.Repo.insert(%Lilac.Artist{name: unknown_artist_name}) do
          {:error, _} -> Lilac.Errors.Meta.unknown_database_error()
          artist -> artist
        end
      else
        Lilac.Errors.Artist.artist_doesnt_exist()
      end
    end
  end

  @spec handle_unknown_artist(binary) :: binary | nil
  def handle_unknown_artist(artist_name) do
    case artist_info(%Params.ArtistInfo{artist: artist_name}) do
      {:ok, response} ->
        response.name

      {:error, %{error_code: 6}} ->
        nil
    end
  end
end
