defmodule Lilac.Servers.Converting do
  use GenServer

  alias Lilac.Services.Converting

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
    IO.puts("Converting page...")

    scrobbles = page["recenttracks"]["track"]

    _artist_map = convert_artists(scrobbles)

    {:noreply, :ok}
  end

  # Helpers

  @spec convert_artists([map]) :: map
  defp convert_artists(scrobbles) do
    artists = Enum.map(scrobbles, fn s -> s["artist"]["#text"] end)

    artist_map = Converting.generate_artist_map(artists)

    Converting.create_missing_artists(artist_map, artists)
  end
end
