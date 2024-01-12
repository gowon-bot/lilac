defmodule Lilac.Sync.Conversion.Cache do
  use GenServer

  alias Lilac.Sync
  alias Lilac.Sync.{Registry, Conversion}
  alias Lilac.NestedMap

  @type raw_artist :: binary
  @type raw_album :: {binary, binary}
  @type raw_track :: {binary, binary, binary}

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.conversion_cache(user))
  end

  @impl true
  @spec init(term) :: {:ok, map}
  def init(_) do
    {:ok, %{}}
  end

  @spec add_scrobbles(
          Lilac.User.t(),
          Sync.Converter.scrobbles_type(),
          NestedMap.t(),
          NestedMap.t(),
          NestedMap.t()
        ) :: term
  def add_scrobbles(user, scrobbles, artist_map, album_map, track_map) do
    GenServer.call(
      Registry.conversion_cache(user),
      {:add_scrobbles, scrobbles, artist_map, album_map, track_map}
    )
  end

  @spec get_cache(Lilac.User.t()) :: [map]
  def get_cache(user) do
    GenServer.call(Registry.conversion_cache(user), :get_cache)
  end

  @spec get_unconverted_artists(Lilac.User.t(), Sync.Converter.scrobbles_type()) :: [raw_artist()]
  def get_unconverted_artists(user, scrobbles) do
    GenServer.call(Registry.conversion_cache(user), {:get_unconverted_artists, scrobbles})
  end

  @spec get_unconverted_albums(Lilac.User.t(), Sync.Converter.scrobbles_type()) :: [raw_album()]
  def get_unconverted_albums(user, scrobbles) do
    GenServer.call(Registry.conversion_cache(user), {:get_unconverted_albums, scrobbles})
  end

  @spec get_unconverted_tracks(Lilac.User.t(), Sync.Converter.scrobbles_type()) :: [raw_track()]
  def get_unconverted_tracks(user, scrobbles) do
    GenServer.call(Registry.conversion_cache(user), {:get_unconverted_tracks, scrobbles})
  end

  @spec get_artist_id(Lilac.User.t(), binary) :: integer | nil
  def get_artist_id(user, artist) do
    GenServer.call(Registry.conversion_cache(user), {:get_artist_id, artist})
  end

  @spec get_album_id(Lilac.User.t(), binary, binary) :: integer | nil
  def get_album_id(user, artist, album) do
    GenServer.call(Registry.conversion_cache(user), {:get_album_id, artist, album})
  end

  @impl true
  def handle_call(:get_cache, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_call({:get_unconverted_artists, scrobbles}, _from, state) do
    {:reply,
     scrobbles
     |> Enum.map(fn s -> s.artist end)
     |> Enum.filter(fn a -> not Conversion.Map.has_artist?(state, a) end), state}
  end

  @impl true
  def handle_call({:get_unconverted_albums, scrobbles}, _from, state) do
    {:reply,
     scrobbles
     |> Enum.map(fn s -> {s.artist, s.album} end)
     |> Enum.filter(fn {a, l} -> not Conversion.Map.has_album?(state, a, l) end), state}
  end

  @impl true
  def handle_call({:get_unconverted_tracks, scrobbles}, _from, state) do
    {:reply,
     scrobbles
     |> Enum.map(fn s -> {s.artist, s.album, s.name} end)
     |> Enum.filter(fn {a, l, t} -> not Conversion.Map.has_track?(state, a, l, t) end), state}
  end

  @impl true
  def handle_call({:get_artist_id, artist}, _from, state) do
    {:reply, Conversion.Map.get_artist_id(state, artist), state}
  end

  @impl true
  def handle_call({:get_album_id, artist, album}, _from, state) do
    {:reply, Conversion.Map.get_album_id(state, artist, album), state}
  end

  @impl true
  def handle_call(
        {:add_scrobbles, scrobbles, artist_map, album_map, track_map},
        _from,
        state
      ) do
    IO.puts("Adding #{length(scrobbles)} scrobbles to the cache")

    {:reply, :ok,
     scrobbles
     |> Enum.reduce(state, add_scrobble_to_state(artist_map, album_map, track_map))}
  end

  defp add_scrobble_to_state(artist_map, album_map, track_map) do
    fn s, state ->
      artist_id =
        NestedMap.get(artist_map, s.artist) || Conversion.Map.get_artist_id(state, s.artist)

      album_id =
        NestedMap.get(album_map, [artist_id, s.album]) ||
          Conversion.Map.get_album_id(state, s.artist, s.album)

      track_id = NestedMap.get(track_map, [artist_id, album_id, s.name])

      state
      |> Conversion.Map.increment_artist(
        artist_id,
        s.artist,
        s.scrobbled_at
      )
      |> Conversion.Map.increment_album(
        album_id,
        s.artist,
        s.album,
        s.scrobbled_at
      )
      |> Conversion.Map.increment_track(
        track_id,
        s.artist,
        s.album,
        s.name,
        s.scrobbled_at
      )
    end
  end
end
