defmodule Lilac.Servers.Converting do
  use GenServer

  alias Lilac.Services.Converting
  alias Lilac.{ConversionMap, CountingMap}

  # Client API

  def convert_page(pid, page) do
    GenServer.cast(pid, {:convert_page, page})
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
  def handle_cast({:convert_page, page}, _state) do
    scrobbles =
      page["recenttracks"]["track"]
      |> Enum.filter(fn track -> not Map.has_key?(track, "@attr") end)

    artist_map = convert_artists(scrobbles)
    album_map = convert_albums(artist_map, scrobbles)
    track_map = convert_tracks(artist_map, album_map, scrobbles)

    counting_maps = count(scrobbles, artist_map, album_map, track_map)

    :ok = Lilac.Servers.Counting.upsert(CountingServer, %Lilac.User{id: 1}, counting_maps)

    {:noreply, :ok}
  end

  # Helpers

  @spec convert_artists([map]) :: map
  def convert_artists(scrobbles) do
    artists = Enum.map(scrobbles, fn s -> s["artist"]["#text"] end)

    artist_map = Converting.generate_artist_map(artists)

    Converting.create_missing_artists(artist_map, artists)
  end

  @spec convert_albums(map, [map]) :: map
  def convert_albums(artist_map, scrobbles) do
    albums =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s["album"]["#text"])
        |> Map.put(:artist, s["artist"]["#text"])
      end)

    album_map = Converting.generate_album_map(artist_map, albums)

    Converting.create_missing_albums(artist_map, album_map, albums)
  end

  @spec convert_tracks(map, map, [map]) :: map
  def convert_tracks(artist_map, album_map, scrobbles) do
    tracks =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s["name"])
        |> Map.put(:album, s["album"]["#text"])
        |> Map.put(:artist, s["artist"]["#text"])
      end)

    track_map = Converting.generate_track_map(artist_map, album_map, tracks)

    Converting.create_missing_tracks(artist_map, album_map, track_map, tracks)
  end

  @spec count([map], map, map, map) :: CountingMap.counting_maps()
  def count(scrobbles, artist_map, album_map, track_map) do
    counting_maps = %{artists: %{}, albums: %{}, tracks: %{}}

    Enum.reduce(scrobbles, counting_maps, fn scrobble, counting_maps ->
      artist_id = ConversionMap.get(artist_map, scrobble["artist"]["#text"])
      album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble["album"]["#text"]])
      track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble["name"]])

      counting_maps
      |> Map.put(:artists, CountingMap.increment(counting_maps.artists, artist_id))
      |> Map.put(:albums, CountingMap.increment(counting_maps.albums, album_id))
      |> Map.put(:tracks, CountingMap.increment(counting_maps.tracks, track_id))
    end)
  end
end
