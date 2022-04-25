defmodule Lilac.Services.Converting do
  import Ecto.Query, only: [from: 2]

  # Entities
  alias Lilac.{Artist}
  alias Lilac.ConversionMap
  alias Lilac.Database.InsertHelpers

  @spec generate_artist_map([%Artist{}]) :: map
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
end
