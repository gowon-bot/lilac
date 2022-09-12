defmodule Lilac.LastFM do
  alias Lilac.LastFM.API
  alias Lilac.LastFM.API.Params
  alias __MODULE__.Responses

  import Ecto.Query, only: [from: 2]

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

  @spec album_info(Params.AlbumInfo.t()) :: {:ok, %Responses.AlbumInfo{}} | {:error, struct}
  def album_info(params) do
    params
    |> API.Params.build("album.getInfo")
    |> API.get()
    |> API.handle_response(&Responses.AlbumInfo.from_map/1)
  end

  @spec track_info(Params.TrackInfo.t()) :: {:ok, %Responses.TrackInfo{}} | {:error, struct}
  def track_info(params) do
    params
    |> API.Params.build("track.getInfo")
    |> API.get()
    |> API.handle_response(&Responses.TrackInfo.from_map/1)
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
        Lilac.Errors.Entities.artist_doesnt_exist()
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

  @spec get_album(binary, binary) :: {:error, struct} | {:ok, Lilac.Album.t()}
  def get_album(artist_name, album_name) do
    case get_artist(artist_name) do
      {:ok, artist} ->
        album = Lilac.Repo.get_by(Lilac.Album, %{artist_id: artist.id, name: album_name})

        if !is_nil(album) do
          {:ok, album |> Map.put(:artist, artist)}
        else
          unknown_album_name = handle_unknown_album(artist.name, album_name)

          if !is_nil(unknown_album_name) do
            case Lilac.Repo.insert(%Lilac.Album{artist: artist, name: unknown_album_name}) do
              {:error, _} -> Lilac.Errors.Meta.unknown_database_error()
              album -> album
            end
          else
            Lilac.Errors.Entities.album_doesnt_exist()
          end
        end

      error ->
        error
    end
  end

  @spec handle_unknown_album(binary, binary) :: binary | nil
  def handle_unknown_album(artist_name, album_name) do
    case album_info(%Params.AlbumInfo{artist: artist_name, album: album_name}) do
      {:ok, response} -> response.name
      {:error, %{error_code: 6}} -> nil
    end
  end

  @spec get_ambiguous_track(binary, binary) :: {:error, struct} | {:ok, Lilac.Track.Ambiguous.t()}
  def get_ambiguous_track(artist_name, track_name) do
    case get_artist(artist_name) do
      {:ok, artist} ->
        tracks =
          from(t in Lilac.Track,
            where: t.artist_id == ^artist.id and t.name == ^track_name
          )
          |> Lilac.Repo.all()

        if length(tracks) != 0 do
          {:ok,
           %Lilac.Track.Ambiguous{
             name: Enum.at(tracks, 0).name,
             artist: artist,
             tracks: tracks |> Enum.map(fn t -> t |> Map.put(:artist, artist) end)
           }}
        else
          unknown_track = handle_unknown_track(artist.name, track_name)

          if !is_nil(unknown_track) do
            case get_album(artist.name, unknown_track.album) do
              {:ok, album} ->
                case Lilac.Repo.insert(%Lilac.Track{
                       artist: artist,
                       name: unknown_track.name,
                       album: album
                     }) do
                  {:error, _} ->
                    Lilac.Errors.Meta.unknown_database_error()

                  track ->
                    {:ok,
                     %Lilac.Track.Ambiguous{
                       name: track.name,
                       artist: artist,
                       tracks: [track]
                     }}
                end

              error ->
                error
            end
          else
            Lilac.Errors.Entities.album_doesnt_exist()
          end
        end

      error ->
        error
    end
  end

  @spec handle_unknown_track(binary, binary) :: %{track: binary, album: binary} | nil
  def handle_unknown_track(artist_name, track_name) do
    case track_info(%Params.TrackInfo{artist: artist_name, track: track_name}) do
      {:ok, response} -> %{track: response.name, album: response.album}
      {:error, %{error_code: 6}} -> nil
    end
  end
end
