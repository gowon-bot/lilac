defmodule Lilac.ConversionMap do
  @moduledoc """
  ConversionMap holds methods to interact with maps
  specialized for converting raw entities to ids

  eg. Converting {artist: "WJSN", name: "WJ Please?"}  ->  12467 (id)

  All keys are downcased, and nested entities can safely be accessed
  """

  @type conversion_key :: String.t() | integer

  @spec add(map, conversion_key, integer) :: map
  def add(map, key, value) do
    Map.put(map, clean_key(key), value)
  end

  @spec add_nested(map, [conversion_key], integer) :: map
  def add_nested(map, keys, value) do
    keys =
      keys
      |> clean_keys()
      |> generate_put_keys()

    put_in(map, keys, value)
  end

  @spec has?(map, conversion_key) :: boolean
  def has?(map, key) do
    Map.has_key?(map, clean_key(key))
  end

  @spec has_nested?(map, [conversion_key]) :: boolean
  def has_nested?(map, keys) do
    get_nested(map, keys) != nil
  end

  @spec get(map, conversion_key) :: integer
  def get(map, key) do
    Map.get(map, clean_key(key))
  end

  @spec get_nested(map, [conversion_key]) :: integer
  def get_nested(map, keys) do
    # If any of the keys are nil, it doesn't exist
    if length(Enum.filter(keys, fn key -> key != nil end)) != length(keys) do
      nil
    else
      get_in(map, clean_keys(keys))
    end
  end

  @spec filter_unmapped_keys(map, [conversion_key]) :: [conversion_key]
  def filter_unmapped_keys(map, keys) do
    Enum.filter(keys, fn key -> not has?(map, key) end)
  end

  # Helpers
  @spec clean_keys([conversion_key]) :: [conversion_key]
  defp clean_keys(keys) do
    keys |> Enum.map(&clean_key/1)
  end

  @spec clean_key(conversion_key) :: conversion_key
  defp clean_key(key) do
    cond do
      is_nil(key) -> ""
      is_bitstring(key) -> String.downcase(key)
      true -> key
    end
  end

  defp generate_put_keys(keys) do
    (Enum.drop(keys, -1)
     |> Enum.map(fn key -> Access.key(key, %{}) end)) ++ [List.last(keys)]
  end
end
