defmodule Lilac.ConvertingServer do
  use GenServer, restart: :transient

  alias Lilac.Converting
  alias Lilac.{ConversionMap, CountingMap}
  alias Lilac.LastFM.Responses

  @typep scrobbles_type :: [Responses.RecentTracks.RecentTrack.t()]

  # Client API

  @spec convert_page(pid, Responses.RecentTracks.t(), Lilac.User.t()) :: :ok
  def convert_page(pid, page, user) do
    GenServer.cast(
      pid,
      {:convert_page, {page, user, Lilac.IndexingSupervisor.indexing_progress_pid(user)}}
    )
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, %{user: user})
  end

  @impl true
  @spec init(%{user: Lilac.User.t()}) :: {:ok, map}
  def init(opts) do
    {:ok, opts}
  end

  @impl true
  @spec handle_cast({:convert_page, {Responses.RecentTracks.t(), Lilac.User.t(), pid}}, term) ::
          {:noreply, :ok}
  def handle_cast({:convert_page, {page, user, indexing_progress_pid}}, state) do
    # user = state.user

    scrobbles = page.tracks |> Enum.filter(&(not &1.is_now_playing))

    artist_map = convert_artists(scrobbles)

    album_map = convert_albums(artist_map, scrobbles)

    track_map = convert_tracks(artist_map, album_map, scrobbles)

    counting_maps = count(scrobbles, artist_map, album_map, track_map)

    :ok = Lilac.CountingServer.upsert(CountingServer, user, counting_maps)

    insert_scrobbles(scrobbles, artist_map, album_map, track_map, user)

    Lilac.IndexingProgressServer.capture_progress(indexing_progress_pid, user, page)

    {:noreply, state}
  end

  # Helpers

  @spec convert_artists(scrobbles_type) :: map
  def convert_artists(scrobbles) do
    artists = Enum.map(scrobbles, fn s -> s.artist end)

    Converting.convert_artists(artists)
  end

  @spec convert_albums(map, scrobbles_type) :: map
  def convert_albums(artist_map, scrobbles) do
    albums =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s.album)
        |> Map.put(:artist, s.artist)
      end)

    album_map = Converting.generate_album_map(artist_map, albums)

    Converting.create_missing_albums(artist_map, album_map, albums)
  end

  @spec convert_tracks(map, map, scrobbles_type) :: map
  def convert_tracks(artist_map, album_map, scrobbles) do
    tracks =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s.name)
        |> Map.put(:album, s.album)
        |> Map.put(:artist, s.artist)
      end)

    track_map = Converting.generate_track_map(artist_map, album_map, tracks)

    Converting.create_missing_tracks(artist_map, album_map, track_map, tracks)
  end

  @spec count(scrobbles_type, map, map, map) :: CountingMap.counting_maps()
  def count(scrobbles, artist_map, album_map, track_map) do
    counting_maps = %{artists: %{}, albums: %{}, tracks: %{}}

    maps =
      Enum.reduce(scrobbles, counting_maps, fn scrobble, counting_maps ->
        artist_id = ConversionMap.get(artist_map, scrobble.artist)
        album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble.album])
        track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble.name])

        counting_maps
        |> Map.put(:artists, CountingMap.increment(counting_maps.artists, artist_id))
        |> Map.put(:albums, CountingMap.increment(counting_maps.albums, album_id))
        |> Map.put(:tracks, CountingMap.increment(counting_maps.tracks, track_id))
      end)

    maps
  end

  @spec insert_scrobbles(scrobbles_type, map, map, map, Lilac.User.t()) :: no_return()
  def insert_scrobbles(scrobbles, artist_map, album_map, track_map, user) do
    converted_scrobbles =
      Enum.map(scrobbles, fn scrobble ->
        artist_id = ConversionMap.get(artist_map, scrobble.artist)
        album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble.album])
        track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble.name])

        %{
          user_id: user.id,
          artist_id: artist_id,
          album_id: album_id,
          track_id: track_id,
          scrobbled_at: scrobble.scrobbled_at
        }
      end)

    Lilac.Repo.insert_all(Lilac.Scrobble, converted_scrobbles)
  end
end
