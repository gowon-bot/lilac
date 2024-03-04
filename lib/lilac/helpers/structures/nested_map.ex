defmodule Lilac.NestedMap do
  @moduledoc """
  NestedMap holds methods to interact with maps
  specialized for converting raw entities' names to ids

  eg. Converting {artist: "WJSN"}  ->  109 (id)
  eg. Converting {artist: "WJSN", album: "WJ Please?"}  ->  12467 (id)

  *All keys are downcased*, and nested entities can safely be accessed
  """

  @type t() :: map
  @type conversion_key :: String.t() | integer

  @spec add(map, [conversion_key], integer) :: map
  def add(map, keys, value) when is_list(keys) do
    keys =
      keys
      |> clean_keys()
      |> generate_put_keys()

    put_in(map, keys, value)
  end

  @spec add(map, conversion_key, integer) :: map
  def add(map, key, value) do
    Map.put(map, clean_key(key), value)
  end

  @spec has?(map, [conversion_key]) :: boolean
  def has?(map, keys) when is_list(keys) do
    get(map, keys) != nil
  end

  @spec has?(map, conversion_key) :: boolean
  def has?(map, key) do
    Map.has_key?(map, clean_key(key))
  end

  @spec get(map, [conversion_key]) :: integer
  def get(map, keys) when is_list(keys) do
    get_in(map, clean_keys(keys))
  end

  @spec get(map, conversion_key) :: integer
  def get(map, key) do
    Map.get(map, clean_key(key))
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
      is_bitstring(key) || is_binary(key) -> String.downcase(key)
      true -> key
    end
  end

  defp generate_put_keys(keys) do
    (Enum.drop(keys, -1)
     |> Enum.map(fn key -> Access.key(key, %{}) end)) ++ [List.last(keys)]
  end
end
