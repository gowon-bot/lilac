defmodule Lilac.CountingServer do
  use GenServer

  alias Lilac.CountingMap

  # Client api

  def upsert(user, counting_maps) do
    pid = Lilac.IndexingSupervisor.couting_pid(user)

    GenServer.cast(pid, {:upsert, {counting_maps}})
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: __MODULE__)
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
  end

  @impl true
  @spec handle_cast({:upsert, {CountingMap.counting_maps()}}, %{user: Lilac.User.t()}) ::
          {:noreply, map}
  def handle_cast({:upsert, {counting_maps}}, %{user: user}) do
    Lilac.Counting.upsert_artist_counts(user, counting_maps.artists)
    Lilac.Counting.upsert_album_counts(user, counting_maps.albums)
    Lilac.Counting.upsert_track_counts(user, counting_maps.tracks)

    {:noreply, %{user: user}}
  end
end
