defmodule Lilac.CountingServer do
  use GenServer

  alias Lilac.CountingMap

  # Client api

  def upsert(user, counting_maps, recent_tracks_page) do
    GenServer.cast(
      Lilac.IndexerRegistry.counting_server_name(user),
      {:upsert, {counting_maps, recent_tracks_page}}
    )
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Lilac.IndexerRegistry.counting_server_name(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user, pages: 0}}
  end

  @impl true
  @spec handle_cast(
          {:upsert, {CountingMap.counting_maps(), Lilac.LastFM.Responses.RecentTracks.t()}},
          %{user: Lilac.User.t()}
        ) ::
          {:noreply, map}
  def handle_cast({:upsert, {counting_maps, recent_tracks_page}}, %{user: user, pages: pages}) do
    Lilac.Counting.upsert_artist_counts(user, counting_maps.artists)
    Lilac.Counting.upsert_album_counts(user, counting_maps.albums)
    Lilac.Counting.upsert_track_counts(user, counting_maps.tracks)

    Lilac.IndexingProgressServer.capture_progress(user, recent_tracks_page)
    Lilac.ConvertingQueue.decrement_queue(user)

    {:noreply, %{user: user, pages: pages + 1}}
  end
end
