defmodule Lilac.ConvertingServer do
  use GenServer

  alias Lilac.Converting
  alias Lilac.{ConversionMap, CountingMap}
  alias Lilac.LastFM.Responses

  @typep scrobbles_type :: [Responses.RecentTracks.RecentTrack.t()]

  defp cache_reset_page, do: 250

  # Client API

  @spec convert_page(Lilac.User.t(), Responses.RecentTracks.t()) :: :ok
  def convert_page(user, page) do
    GenServer.cast(Lilac.IndexerRegistry.converting_server_name(user), {:convert_page, {page}})
  end

  # Server callbacks

  def start_link(user) do
    GenServer.start_link(__MODULE__, user,
      name: Lilac.IndexerRegistry.converting_server_name(user)
    )
  end

  @impl true
  @spec init(Lilac.User.t()) :: {:ok, map}
  def init(user) do
    {:ok, %{user: user, conversion_maps: blank_conversion_map_cache()}}
  end

  @impl true
  @spec handle_cast({:convert_page, {Responses.RecentTracks.t(), Lilac.User.t(), pid}}, %{
          user: Lilac.User.t(),
          conversion_maps: map
        }) ::
          {:noreply, :ok}
  def handle_cast({:convert_page, {page}}, %{user: user, conversion_maps: conversion_maps}) do
    scrobbles = page.tracks |> Enum.filter(&(not &1.is_now_playing))

    # Reset the cache after x pages to stop the cache from getting too big
    # Most users' libraries should fit within zero resets
    conversion_maps = maybe_reset_map_cache(conversion_maps, page.meta.page)

    artist_map = convert_artists(scrobbles, conversion_maps.artist)

    album_map = convert_albums(artist_map, scrobbles, conversion_maps.album)

    track_map = convert_tracks(artist_map, album_map, scrobbles, conversion_maps.track)

    counting_maps = count(scrobbles, artist_map, album_map, track_map)

    insert_scrobbles(scrobbles, artist_map, album_map, track_map, user)

    :ok = Lilac.CountingServer.upsert(user, counting_maps, page)

    {:noreply,
     %{user: user, conversion_maps: %{artist: artist_map, album: album_map, track: track_map}}}
  end

  # Helpers

  @spec convert_artists(scrobbles_type, map) :: map
  def convert_artists(scrobbles, existing_conversion_map) do
    artists =
      scrobbles
      |> Enum.map(fn s -> s.artist end)
      |> Enum.filter(fn a -> !ConversionMap.has?(existing_conversion_map, a) end)

    Converting.convert_artists(artists) |> Map.merge(existing_conversion_map)
  end

  @spec convert_albums(map, scrobbles_type, map) :: map
  def convert_albums(artist_map, scrobbles, existing_conversion_map) do
    albums =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s.album)
        |> Map.put(:artist, s.artist)
      end)
      |> Enum.filter(fn %{name: name, artist: artist} ->
        !ConversionMap.has_nested?(existing_conversion_map, [
          ConversionMap.get(artist_map, artist),
          name
        ])
      end)

    Converting.convert_albums(artist_map, albums)
    |> Map.merge(existing_conversion_map, fn _k, v1, v2 -> Map.merge(v1, v2) end)
  end

  @spec convert_tracks(map, map, scrobbles_type, map) :: map
  def convert_tracks(artist_map, album_map, scrobbles, existing_conversion_map) do
    tracks =
      Enum.map(scrobbles, fn s ->
        %{}
        |> Map.put(:name, s.name)
        |> Map.put(:album, s.album)
        |> Map.put(:artist, s.artist)
      end)
      |> Enum.filter(fn %{name: name, album: album, artist: artist} ->
        artist_id = ConversionMap.get(artist_map, artist)
        album_id = ConversionMap.get_nested(album_map, [artist_id, album])

        !ConversionMap.has_nested?(existing_conversion_map, [artist_id, album_id, name])
      end)

    Converting.convert_tracks(artist_map, album_map, tracks)
    |> Map.merge(existing_conversion_map, fn _k, v1, v2 ->
      Map.merge(v1, v2, fn _k, v3, v4 -> Map.merge(v3, v4) end)
    end)
  end

  @spec count(scrobbles_type, map, map, map) :: CountingMap.counting_maps()
  def count(scrobbles, artist_map, album_map, track_map) do
    counting_maps = %{artists: %{}, albums: %{}, tracks: %{}}

    maps =
      Enum.reduce(scrobbles, counting_maps, fn scrobble, counting_maps ->
        artist_id = ConversionMap.get(artist_map, scrobble.artist)
        album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble.album])
        track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble.name])

        counting_maps
        |> Map.put(:artists, CountingMap.increment(counting_maps.artists, artist_id))
        |> Map.put(:albums, CountingMap.increment(counting_maps.albums, album_id))
        |> Map.put(:tracks, CountingMap.increment(counting_maps.tracks, track_id))
      end)

    maps
  end

  @spec insert_scrobbles(scrobbles_type, map, map, map, Lilac.User.t()) :: no_return()
  def insert_scrobbles(scrobbles, artist_map, album_map, track_map, user) do
    converted_scrobbles =
      Enum.map(scrobbles, fn scrobble ->
        artist_id = ConversionMap.get(artist_map, scrobble.artist)
        album_id = ConversionMap.get_nested(album_map, [artist_id, scrobble.album])
        track_id = ConversionMap.get_nested(track_map, [artist_id, album_id, scrobble.name])

        %{
          user_id: user.id,
          artist_id: artist_id,
          album_id: album_id,
          track_id: track_id,
          scrobbled_at: scrobble.scrobbled_at
        }
      end)

    Lilac.Repo.insert_all(Lilac.Scrobble, converted_scrobbles)
  end

  defp maybe_reset_map_cache(cache, page_number) do
    if rem(page_number, cache_reset_page()) == 0,
      do: blank_conversion_map_cache(),
      else: cache
  end

  defp blank_conversion_map_cache do
    %{artist: %{}, album: %{}, track: %{}}
  end
end
