defmodule Lilac.Converting do
  import Ecto.Query, only: [from: 1, from: 2]

  alias Lilac.ConversionMap
  alias Lilac.Converting.Caching

  # Entities
  alias Lilac.{Artist, Album, Track}

  # Artists

  @spec generate_artist_map([String.t()]) :: map
  def generate_artist_map(artists) do
    artists = Enum.uniq(artists)

    conversion_map = Caching.fetch_cached_artists(artists)

    uncached_artists = Enum.filter(artists, fn a -> !ConversionMap.has?(conversion_map, a) end)

    query = from(a in Artist, where: a.name in ^uncached_artists)

    artists = query |> Lilac.Repo.all()

    if length(artists) > 0, do: Caching.cache_artists(artists)

    add_artists_to_conversion_map(artists, conversion_map)
  end

  @spec create_missing_artists(map, [String.t()]) :: map
  def create_missing_artists(conversion_map, artists) do
    artists = ConversionMap.filter_unmapped_keys(conversion_map, Enum.uniq(artists))

    if length(artists) == 0 do
      conversion_map
    else
      new_artists = Enum.map(artists, fn a -> %{name: a} end)

      {_count, inserted_artists} = Lilac.Repo.insert_all(Artist, new_artists, returning: true)

      Caching.cache_artists(inserted_artists)

      add_artists_to_conversion_map(inserted_artists, conversion_map)
    end
  end

  @spec add_artists_to_conversion_map([%Artist{}], map) :: map
  defp add_artists_to_conversion_map(artists, map) do
    Enum.reduce(
      artists,
      map,
      fn artist, acc -> ConversionMap.add(acc, artist.name, artist.id) end
    )
  end

  # Albums

  @spec generate_album_map(map, [Album.raw()]) :: map
  def generate_album_map(artist_map, albums) do
    albums =
      Enum.uniq(albums)
      |> Enum.map(fn album -> raw_album_to_queryable(album, artist_map) end)

    albums =
      from(l in Album)
      |> Lilac.Database.CustomFunctions.albums_in(albums)
      |> Lilac.Repo.all()

    add_albums_to_conversion_map(albums)
  end

  @spec create_missing_albums(map, map, [Album.raw()]) :: map
  def create_missing_albums(artist_map, conversion_map, albums) do
    albums =
      albums
      |> Enum.uniq()
      |> Enum.filter(fn album ->
        not ConversionMap.has_nested?(
          conversion_map,
          [ConversionMap.get(artist_map, album.artist), album.name]
        )
      end)

    if length(albums) == 0 do
      conversion_map
    else
      new_albums =
        albums
        |> Enum.map(fn album ->
          %{name: album.name, artist_id: ConversionMap.get(artist_map, album.artist)}
        end)

      {_count, inserted_albums} = Lilac.Repo.insert_all(Album, new_albums, returning: true)

      add_albums_to_conversion_map(inserted_albums, conversion_map)
    end
  end

  @spec add_albums_to_conversion_map([%Album{}], map) :: map
  defp add_albums_to_conversion_map(albums, map \\ %{}) do
    Enum.reduce(
      albums,
      map,
      fn album, acc ->
        ConversionMap.add_nested(acc, [album.artist_id, album.name], album.id)
      end
    )
  end

  @spec raw_album_to_queryable(Album.raw(), map) :: map
  defp raw_album_to_queryable(album, artist_map) do
    album
    |> Map.put(:artist_id, ConversionMap.get(artist_map, album.artist))
    |> Map.delete(:artist)
  end

  # Tracks

  @spec generate_track_map(map, map, [Track.raw()]) :: map
  def generate_track_map(artist_map, album_map, tracks) do
    tracks =
      tracks
      |> Enum.uniq()
      |> Enum.map(fn track -> raw_track_to_queryable(track, artist_map, album_map) end)

    tracks =
      from(l in Track)
      |> Lilac.Database.CustomFunctions.tracks_in(tracks)
      |> Lilac.Repo.all()

    add_tracks_to_conversion_map(tracks)
  end

  @spec create_missing_tracks(map, map, map, [Track.raw()]) :: map
  def create_missing_tracks(artist_map, album_map, conversion_map, tracks) do
    tracks =
      tracks
      |> Enum.uniq()
      |> Enum.filter(fn track ->
        is_track_unmapped?(track, artist_map, album_map, conversion_map)
      end)

    if length(tracks) == 0 do
      conversion_map
    else
      new_tracks =
        tracks
        |> Enum.map(fn track -> raw_track_to_queryable(track, artist_map, album_map) end)

      {_count, inserted_tracks} = Lilac.Repo.insert_all(Track, new_tracks, returning: true)

      add_tracks_to_conversion_map(inserted_tracks, conversion_map)
    end
  end

  @spec add_tracks_to_conversion_map([%Track{}], map) :: map
  defp add_tracks_to_conversion_map(tracks, map \\ %{}) do
    Enum.reduce(
      tracks,
      map,
      fn track, acc ->
        ConversionMap.add_nested(acc, [track.artist_id, track.album_id, track.name], track.id)
      end
    )
  end

  @spec raw_track_to_queryable(Track.raw(), map, map) :: map
  defp raw_track_to_queryable(track, artist_map, album_map) do
    artist_id = ConversionMap.get(artist_map, track.artist)

    track
    |> Map.put(:artist_id, artist_id)
    |> Map.delete(:artist)
    |> Map.put(:album_id, ConversionMap.get_nested(album_map, [artist_id, track.album]))
    |> Map.delete(:album)
  end

  defp is_track_unmapped?(track, artist_map, album_map, conversion_map) do
    artist_id = ConversionMap.get(artist_map, track.artist)
    album_id = ConversionMap.get_nested(album_map, [artist_id, track.album])

    not ConversionMap.has_nested?(
      conversion_map,
      [
        artist_id,
        album_id,
        track.name
      ]
    )
  end
end
