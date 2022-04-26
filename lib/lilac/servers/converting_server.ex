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
    scrobbles =
      page["recenttracks"]["track"]
      |> Enum.filter(fn track -> not Map.has_key?(track, "@attr") end)

    artist_map = convert_artists(scrobbles)

    _albums_map = convert_albums(artist_map, scrobbles)

    {:noreply, :ok}
  end

  # Helpers

  @spec convert_artists([map]) :: map
  defp convert_artists(scrobbles) do
    artists = Enum.map(scrobbles, fn s -> s["artist"]["#text"] end)

    artist_map = Converting.generate_artist_map(artists)

    Converting.create_missing_artists(artist_map, artists)
  end

  @spec convert_albums(map, [map]) :: map
  defp convert_albums(artist_map, scrobbles) do
    albums =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s["album"]["#text"])
        |> Map.put(:artist, s["artist"]["#text"])
      end)

    album_map = Converting.generate_album_map(artist_map, albums)

    Converting.create_missing_albums(artist_map, album_map, albums)
  end
end
