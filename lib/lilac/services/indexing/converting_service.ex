defmodule Lilac.Services.Converting do
  import Ecto.Query, only: [from: 1, from: 2]

  alias Lilac.ConversionMap
  alias Lilac.Database.InsertHelpers

  # Entities
  alias Lilac.{Artist, Album}

  # Artists

  @spec generate_artist_map([String.t()]) :: map
  def generate_artist_map(artists) do
    artists = Enum.uniq(artists)

    query = from(a in Artist, where: a.name in ^artists)

    artists = query |> Lilac.Repo.all()

    add_artists_to_conversion_map(artists)
  end

  @spec create_missing_artists(map, [String.t()]) :: map
  def create_missing_artists(conversion_map, artists) do
    artists = ConversionMap.filter_unmapped_keys(conversion_map, Enum.uniq(artists))

    if length(artists) == 0 do
      conversion_map
    else
      new_artists =
        Enum.map(artists, fn a -> %{name: a} end)
        |> InsertHelpers.add_timestamps_to_many()

      {_count, inserted_artists} = Lilac.Repo.insert_all(Artist, new_artists, returning: true)

      add_artists_to_conversion_map(inserted_artists, conversion_map)
    end
  end

  @spec add_artists_to_conversion_map([%Artist{}], map) :: map
  defp add_artists_to_conversion_map(artists, map \\ %{}) do
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
      |> Enum.map(fn album ->
        album
        |> Map.put(:artist_id, ConversionMap.get(artist_map, album.artist))
        |> Map.delete(:artist)
      end)

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
        |> InsertHelpers.add_timestamps_to_many()

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
end
