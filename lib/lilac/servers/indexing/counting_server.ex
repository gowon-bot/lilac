defmodule Lilac.Servers.Counting do
  use GenServer

  alias Lilac.CountingMap
  alias Lilac.Services.Counting

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
  @spec handle_cast({:upsert}, {%Lilac.User{}, CountingMap.counting_maps()}) ::
          {:noreply, map}
  def handle_cast({:upsert, {user, counting_maps}}, _state) do
    upserts = [
      Task.async(fn -> Counting.upsert_artist_counts(user, counting_maps.artists) end),
      Task.async(fn -> Counting.upsert_album_counts(user, counting_maps.albums) end),
      Task.async(fn -> Counting.upsert_track_counts(user, counting_maps.tracks) end)
    ]

    Task.await_many(upserts)

    {:noreply, %{}}
  end
end
