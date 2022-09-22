defmodule Lilac.Servers.Counting do
  use GenServer, restart: :permanent

  alias Lilac.CountingMap

  # Client api

  def upsert(pid, user, counting_maps) do
    GenServer.cast(pid, {:upsert, {user, counting_maps}})
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
  @spec handle_cast({:upsert, {%Lilac.User{}, CountingMap.counting_maps()}}, term) ::
          {:noreply, map}
  def handle_cast({:upsert, {user, counting_maps}}, _state) do
    Lilac.Counting.upsert_artist_counts(user, counting_maps.artists)
    Lilac.Counting.upsert_album_counts(user, counting_maps.albums)
    Lilac.Counting.upsert_track_counts(user, counting_maps.tracks)

    {:noreply, %{}}
  end
end
