defmodule Lilac.Sync.Converter do
  use GenServer

  alias Lilac.Sync.{Conversion, Registry}
  alias Lilac.LastFM.Responses

  @type scrobbles_type :: [Responses.RecentTracks.RecentTrack.t()]

  # Client API

  @spec process_page(Lilac.User.t(), Responses.RecentTracks.t()) :: :ok
  def process_page(user, page) do
    GenServer.cast(Registry.converter(user), {:process_page, page})
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.converter(user))
  end

  @impl true
  @spec init(Lilac.User.t()) :: {:ok, map}
  def init(user) do
    {:ok, %{user: user}}
  end

  @impl true
  @spec handle_cast({:process_page, Responses.RecentTracks.t()}, %{user: Lilac.User.t()}) ::
          {:reply, :ok, term}
  def handle_cast({:process_page, page}, %{user: user}) do
    scrobbles = page.tracks |> Enum.filter(&(not &1.is_now_playing))

    artist_map = convert_artists(user, scrobbles)
    album_map = convert_albums(user, scrobbles, artist_map)
    track_map = convert_tracks(user, scrobbles, artist_map, album_map)

    Conversion.Cache.add_scrobbles(user, scrobbles, artist_map, album_map, track_map)

    # if user.has_premium do
    # insert_scrobbles(scrobbles, artist_map, album_map, track_map, user)
    # end

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

  # @spec insert_scrobbles(scrobbles_type, map, map, map, Lilac.User.t()) :: no_return()
  # def insert_scrobbles(scrobbles, artist_map, album_map, track_map, user) do
  #   converted_scrobbles =
  #     Enum.map(scrobbles, fn scrobble ->
  #       artist_id = ConversionMap.get(artist_map, scrobble.artist)
  #       album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble.album])
  #       track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble.name])

  #       %{
  #         user_id: user.id,
  #         artist_id: artist_id,
  #         album_id: album_id,
  #         track_id: track_id,
  #         scrobbled_at: scrobble.scrobbled_at
  #       }
  #     end)

  #   Lilac.Repo.insert_all(Lilac.Scrobble, converted_scrobbles)
  # end
end
