defmodule Lilac.Servers.Converting do
  use GenServer

  alias Lilac.Converting
  alias Lilac.{ConversionMap, CountingMap}
  alias Lilac.LastFM.Responses

  @typep scrobbles_type :: [Responses.RecentTracks.RecentTrack.t()]

  # Client API

  def convert_page(pid, page, user) do
    GenServer.cast(pid, {:convert_page, {page, user}})
  end

  # Server callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  @spec handle_cast({:convert_page, {Responses.RecentTracks.t(), %Lilac.User{}}}, term) ::
          {:noreply, :ok}
  def handle_cast({:convert_page, {page, user}}, _state) do
    scrobbles = page.tracks |> Enum.filter(&(not &1.is_now_playing))
    page_number = page.meta.page

    IO.puts("Converting artists for page #{page_number}")
    artist_map = convert_artists(scrobbles)

    IO.puts("Converting albums for page #{page_number}")
    album_map = convert_albums(artist_map, scrobbles)

    IO.puts("Converting tracks for page #{page_number}")
    track_map = convert_tracks(artist_map, album_map, scrobbles)

    IO.puts("Counting for page #{page_number}")
    counting_maps = count(scrobbles, artist_map, album_map, track_map)

    IO.puts("Upserting counts for page #{page_number}")
    :ok = Lilac.Servers.Counting.upsert(CountingServer, user, counting_maps)

    IO.puts("Inserting scrobbles for page #{page_number}")
    insert_scrobbles(scrobbles, artist_map, album_map, track_map, user)

    {:noreply, :ok}
  end

  # Helpers

  @spec convert_artists(scrobbles_type) :: map
  def convert_artists(scrobbles) do
    artists = Enum.map(scrobbles, fn s -> s.artist end)

    artist_map = Converting.generate_artist_map(artists)

    Converting.create_missing_artists(artist_map, artists)
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

  @spec insert_scrobbles(scrobbles_type, map, map, map, %Lilac.User{}) :: no_return()
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
