defmodule Lilac.Sync.Conversion do
  import Ecto.Query, only: [from: 1, from: 2]

  alias Lilac.NestedMap
  alias Lilac.Sync.Conversion.Cache

  # Entities
  alias Lilac.{Artist, Album, Track, Tag}

  # Artists

  @spec convert_artists([Cache.raw_artist()]) :: map
  def convert_artists([]) do
    %{}
  end

  @spec convert_artists([Cache.raw_artist()]) :: map
  def convert_artists(artists) do
    artist_map = generate_artist_map(artists)

    create_missing_artists(artist_map, artists)
  end

  @spec generate_artist_map([Cache.raw_artist()]) :: map
  def generate_artist_map(artists) do
    artists = Enum.uniq(artists)

    query = from(a in Artist, where: a.name in ^artists)

    artists = query |> Lilac.Repo.all()

    add_artists_to_entity_id_map(artists, %{})
  end

  @spec create_missing_artists(map, [Cache.raw_artist()]) :: map
  def create_missing_artists(conversion_map, artists) do
    artists = NestedMap.filter_unmapped_keys(conversion_map, Enum.uniq(artists))

    if length(artists) == 0 do
      conversion_map
    else
      new_artists = Enum.map(artists, fn a -> %{name: a} end)

      {_, inserted_artists} = Lilac.Repo.insert_all(Artist, new_artists, returning: true)

      add_artists_to_entity_id_map(inserted_artists, conversion_map)
    end
  end

  @spec add_artists_to_entity_id_map([Artist.t()], map) :: NestedMap.t()
  defp add_artists_to_entity_id_map(artists, map) do
    Enum.reduce(
      artists,
      map,
      fn artist, acc -> NestedMap.add(acc, artist.name, artist.id) end
    )
  end

  # Albums

  @spec convert_albums(Lilac.User.t(), [Cache.raw_album()], map) :: map
  def convert_albums(_, [], _) do
    %{}
  end

  @spec convert_albums(Lilac.User.t(), [Cache.raw_album()], map) :: map
  def convert_albums(user, albums, artist_map) do
    album_map = generate_album_map(albums, artist_map, user)

    create_missing_albums(artist_map, album_map, albums, user)
  end

  @spec generate_album_map([Cache.raw_album()], map, Lilac.User.t() | nil) :: map
  def generate_album_map(albums, artist_map, user) do
    albums =
      Enum.uniq(albums)
      |> Enum.map(fn album -> raw_album_to_queryable(album, artist_map, user) end)
      |> Enum.reject(fn album -> is_nil(album.artist_id) end)

    albums =
      from(l in Album)
      |> Lilac.Database.CustomFunctions.albums_in(albums)
      |> Lilac.Repo.all()

    add_albums_to_entity_id_map(albums)
  end

  @spec create_missing_albums(map, map, [Cache.raw_album()], Lilac.User.t()) :: map
  def create_missing_albums(artist_map, album_map, albums, user) do
    albums =
      albums
      |> Enum.uniq()
      |> Enum.filter(fn album -> is_album_unmapped?(album, artist_map, album_map, user) end)

    if length(albums) == 0 do
      album_map
    else
      new_albums =
        albums
        |> Enum.map(fn {artist, album} ->
          %{
            name: album,
            artist_id: NestedMap.get(artist_map, artist) || Cache.get_artist_id(user, artist)
          }
        end)

      {_, inserted_albums} = Lilac.Repo.insert_all(Album, new_albums, returning: true)

      add_albums_to_entity_id_map(inserted_albums, album_map)
    end
  end

  @spec add_albums_to_entity_id_map([Album.t()], map) :: NestedMap.t()
  defp add_albums_to_entity_id_map(albums, map \\ %{}) do
    Enum.reduce(
      albums,
      map,
      fn album, acc ->
        NestedMap.add(acc, [album.artist_id, album.name], album.id)
      end
    )
  end

  @spec raw_album_to_queryable(Cache.raw_album(), map, Lilac.User.t() | nil) :: map
  defp raw_album_to_queryable({artist, album}, artist_map, user) do
    %{
      artist_id: NestedMap.get(artist_map, artist) || Cache.get_artist_id(user, artist),
      name: album
    }
  end

  @spec is_album_unmapped?(Cache.raw_album(), map, map, Lilac.User.t()) :: boolean
  defp is_album_unmapped?({artist, album}, artist_map, album_map, user) do
    artist_id =
      NestedMap.get(artist_map, artist) || Cache.get_artist_id(user, artist)

    not NestedMap.has?(album_map, [artist_id, album])
  end

  # Tracks

  @spec convert_tracks(Lilac.User.t(), [Cache.raw_track()], map, map) :: map
  def convert_tracks(_, [], _, _) do
    %{}
  end

  @spec convert_tracks(Lilac.User.t(), [Cache.raw_track()], map, map) :: map
  def convert_tracks(user, tracks, artist_map, album_map) do
    track_map = generate_track_map(artist_map, album_map, tracks, user)
    create_missing_tracks(artist_map, album_map, track_map, tracks, user)
  end

  @spec generate_track_map(map, map, [Cache.raw_track()], Lilac.User.t()) :: map
  def generate_track_map(artist_map, album_map, tracks, user) do
    tracks =
      tracks
      |> Enum.uniq()
      |> Enum.map(fn track -> raw_track_to_queryable(track, artist_map, album_map, user) end)

    unless Enum.empty?(tracks) do
      tracks =
        from(l in Track)
        |> Lilac.Database.CustomFunctions.tracks_in(tracks)
        |> Lilac.Repo.all()

      add_tracks_to_entity_id_map(tracks)
    else
      %{}
    end
  end

  @spec create_missing_tracks(map, map, map, [Cache.raw_track()], Lilac.User.t()) :: map
  def create_missing_tracks(artist_map, album_map, track_map, tracks, user) do
    tracks =
      tracks
      |> Enum.uniq()
      |> Enum.filter(fn track ->
        is_track_unmapped?(track, artist_map, album_map, track_map, user)
      end)

    if length(tracks) == 0 do
      track_map
    else
      new_tracks =
        tracks
        |> Enum.map(fn track -> raw_track_to_queryable(track, artist_map, album_map, user) end)

      {_, inserted_tracks} = Lilac.Repo.insert_all(Track, new_tracks, returning: true)

      add_tracks_to_entity_id_map(inserted_tracks, track_map)
    end
  end

  @spec add_tracks_to_entity_id_map([Track.t()], map) :: NestedMap.t()
  defp add_tracks_to_entity_id_map(tracks, map \\ %{}) do
    Enum.reduce(
      tracks,
      map,
      fn track, acc ->
        NestedMap.add(acc, [track.artist_id, track.album_id, track.name], track.id)
      end
    )
  end

  @spec raw_track_to_queryable(Cache.raw_track(), map, map, Lilac.User.t()) :: map
  defp raw_track_to_queryable({artist, album, track}, artist_map, album_map, user) do
    artist_id = NestedMap.get(artist_map, artist) || Cache.get_artist_id(user, artist)

    album_id =
      NestedMap.get(album_map, [artist_id, album]) ||
        Cache.get_album_id(user, artist, album)

    %{
      name: track,
      artist_id: artist_id,
      album_id: album_id
    }
  end

  @spec is_track_unmapped?(Cache.raw_track(), map, map, map, Lilac.User.t()) :: boolean
  defp is_track_unmapped?({artist, album, track}, artist_map, album_map, track_map, user) do
    artist_id =
      NestedMap.get(artist_map, artist) || Cache.get_artist_id(user, artist)

    album_id =
      NestedMap.get(album_map, [artist_id, album]) || Cache.get_album_id(user, artist, album)

    not NestedMap.has?(track_map, [artist_id, album_id, track])
  end

  # Tags
  @spec convert_tags([String.t()]) :: map
  def convert_tags(tags) do
    tag_map = generate_tag_map(tags)

    create_missing_tags(tag_map, tags)
  end

  @spec generate_tag_map([String.t()]) :: map
  def generate_tag_map(tags) do
    tags = Enum.uniq(tags)

    query = from(t in Tag, where: t.name in ^tags)

    tags = query |> Lilac.Repo.all()

    add_tags_to_conversion_map(tags, %{})
  end

  @spec create_missing_tags(map, [String.t()]) :: map
  def create_missing_tags(conversion_map, tags) do
    tags = NestedMap.filter_unmapped_keys(conversion_map, Enum.uniq(tags))

    if length(tags) == 0 do
      conversion_map
    else
      new_tags = Enum.map(tags, fn t -> %{name: t} end)

      {_count, inserted_tags} = Lilac.Repo.insert_all(Tag, new_tags, returning: true)

      add_tags_to_conversion_map(inserted_tags, conversion_map)
    end
  end

  @spec add_tags_to_conversion_map([Tag.t()], map) :: map
  defp add_tags_to_conversion_map(tags, map) do
    Enum.reduce(
      tags,
      map,
      fn tag, acc -> NestedMap.add(acc, tag.name, tag.id) end
    )
  end
end
