defmodule Lilac.Converting.Caching do
  alias Lilac.ConversionMap

  # 10 minutes
  def default_expiry, do: 60 * 10

  @spec cache_artists([%Lilac.Artist{}]) :: no_return
  def cache_artists(artists) do
    mset =
      List.flatten(
        ["MSET"] ++ List.flatten(Enum.map(artists, fn a -> [artist_key(a.name), a.id] end))
      )

    Redix.pipeline(
      :redix,
      Enum.map(artists, fn a -> ["EXPIRE", artist_key(a.name), default_expiry()] end) ++ [mset]
    )
  end

  @spec fetch_cached_artists([%Lilac.Artist{}]) :: map
  def fetch_cached_artists(artists) do
    artist_names = artists |> Enum.map(fn a -> artist_key(a) end)

    {:ok, ids} = Redix.command(:redix, List.flatten(["MGET", artist_names]))

    ids
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {id, idx}, acc ->
      case id do
        nil -> acc
        id -> ConversionMap.add(acc, Enum.at(artist_names, idx), String.to_integer(id))
      end
    end)
  end

  defp artist_key(artist_name) do
    "lilac-artist-#{artist_name |> String.downcase()}"
  end
end
