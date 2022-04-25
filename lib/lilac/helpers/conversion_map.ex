defmodule Lilac.ConversionMap do
  @spec add(map, String.t(), integer) :: map
  def add(map, artist_name, artist_id) do
    Map.put(map, String.downcase(artist_name), artist_id)
  end

  @spec has?(map, String.t()) :: boolean
  def has?(map, artist_name) do
    Map.has_key?(map, String.downcase(artist_name))
  end

  @spec get(map, String.t()) :: boolean
  def get(map, artist_name) do
    Map.get(map, String.downcase(artist_name))
  end

  @spec filter_unmapped_keys(map, [String.t()]) :: [String.t()]
  def filter_unmapped_keys(map, artists) do
    Enum.filter(artists, fn artist -> not has?(map, artist) end)
  end
end
