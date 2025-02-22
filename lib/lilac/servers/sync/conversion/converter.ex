defmodule Lilac.Sync.Converter do
  use GenServer

  alias Lilac.Sync
  alias Lilac.Sync.{Conversion, Registry, Dataset, ProgressReporter, Syncer}
  alias Lilac.LastFM.Responses

  @type scrobbles_type :: [Responses.RecentTracks.RecentTrack.t()]

  # Client API

  @spec process_page(Lilac.User.t(), Responses.RecentTracks.t(), Sync.Supervisor.action()) ::
          :ok
  def process_page(user, page, action) do
    GenServer.cast(Registry.converter(user), {:process_page, page, action})
  end

  @spec persist_cache(Lilac.User.t(), Sync.Supervisor.action()) :: :ok
  def persist_cache(user, action) do
    GenServer.cast(Registry.converter(user), {:persist_cache, action})
  end

  @spec fetch_error(Sync.Supervisor.action(), Lilac.User.t(), struct) :: :ok
  def fetch_error(action, user, error) do
    GenServer.cast(Registry.converter(user), {:fetch_error, action, error})
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.converter(user))
  end

  @impl true
  @spec init(Lilac.User.t()) :: {:ok, map}
  def init(user) do
    {:ok, %{user: user, converted_pages: 0}}
  end

  @impl true
  @spec handle_cast({:process_page, Responses.RecentTracks.t(), Sync.Supervisor.action()}, %{
          user: Lilac.User.t()
        }) ::
          {:reply, :ok, term}
  def handle_cast({:process_page, page, action}, %{user: user, converted_pages: converted_pages}) do
    try do
      handle_page(user, page, action, converted_pages)
    rescue
      error ->
        Sync.Subscriptions.report_error(action, user, error)

        Syncer.terminate_sync(user)

        {:noreply, %{user: user}}
    end
  end

  @impl true
  @spec handle_cast({:persist_cache, Sync.Supervisor.action()}, %{user: Lilac.User.t()}) ::
          {:noreply, term}
  def handle_cast({:persist_cache, action}, %{user: user, converted_pages: converted_pages}) do
    {artist_counts, album_counts, track_counts} = Conversion.Cache.get_counts(user)

    case action do
      :sync -> Dataset.insert_counts(user, artist_counts, album_counts, track_counts)
      :update -> Dataset.upsert_counts(user, artist_counts, album_counts, track_counts)
    end

    Syncer.terminate_sync(user)

    {:noreply, %{user: user, converted_pages: converted_pages}}
  end

  @impl true
  @spec handle_cast({:fetch_error, Sync.Supervisor.action(), struct}, %{
          user: Lilac.User.t()
        }) ::
          {:noreply, term}
  def handle_cast({:fetch_error, action, error}, %{user: user}) do
    Sync.Subscriptions.report_error(action, user, error)

    Syncer.terminate_sync(user)

    {:noreply, %{user: user}}
  end

  # Helpers

  @spec convert_artists(Lilac.User.t(), scrobbles_type) :: no_return()
  def convert_artists(user, scrobbles) do
    unconverted = Conversion.Cache.get_unconverted_artists(user, scrobbles)
    Conversion.convert_artists(unconverted)
  end

  @spec convert_albums(Lilac.User.t(), scrobbles_type, map) :: no_return()
  def convert_albums(user, scrobbles, artist_map) do
    unconverted = Conversion.Cache.get_unconverted_albums(user, scrobbles)
    Conversion.convert_albums(user, unconverted, artist_map)
  end

  @spec convert_tracks(User.t(), scrobbles_type, map, map) :: no_return()
  def convert_tracks(user, scrobbles, artist_map, album_map) do
    unconverted = Conversion.Cache.get_unconverted_tracks(user, scrobbles)
    Conversion.convert_tracks(user, unconverted, artist_map, album_map)
  end

  @spec insert_scrobbles(scrobbles_type, map, map, map, Lilac.User.t()) :: no_return()
  def insert_scrobbles(scrobbles, artist_map, album_map, track_map, user) do
    converted_scrobbles =
      Enum.map(scrobbles, fn scrobble ->
        artist_id = Conversion.Cache.get_artist_id(artist_map, user, scrobble.artist)

        album_id =
          Conversion.Cache.get_album_id(
            album_map,
            user,
            {artist_id, scrobble.artist},
            scrobble.album
          )

        track_id =
          Conversion.Cache.get_track_id(
            track_map,
            user,
            {artist_id, scrobble.artist},
            {album_id, scrobble.album},
            scrobble.name
          )

        %{
          user_id: user.id,
          artist_id: artist_id,
          artist_name: scrobble.artist,
          album_id: album_id,
          album_name: scrobble.album,
          track_id: track_id,
          track_name: scrobble.name,
          scrobbled_at: scrobble.scrobbled_at
        }
      end)

    Lilac.Repo.insert_all(Lilac.Scrobble, converted_scrobbles)
  end

  @spec handle_page(Lilac.User.t(), Responses.RecentTracks.t(), Sync.Supervisor.action(), integer) ::
          {:noreply, map}
  defp handle_page(user, page, action, converted_pages) do
    scrobbles = page.tracks |> Enum.filter(&(not &1.is_now_playing))

    artist_map = convert_artists(user, scrobbles)
    album_map = convert_albums(user, scrobbles, artist_map)
    track_map = convert_tracks(user, scrobbles, artist_map, album_map)

    Conversion.Cache.add_scrobbles(user, scrobbles, artist_map, album_map, track_map)

    if user.has_premium do
      insert_scrobbles(scrobbles, artist_map, album_map, track_map, user)
    end

    ProgressReporter.capture_progress(user, :fetching, length(scrobbles))

    if converted_pages + 1 == page.meta.total_pages do
      handle_last_page(user, action)
    end

    {:noreply, %{user: user, converted_pages: converted_pages + 1}}
  end

  @spec handle_last_page(Lilac.User.t(), Sync.Supervisor.action()) :: no_return()
  defp handle_last_page(user, action) do
    persist_cache(user, action)
  end
end
