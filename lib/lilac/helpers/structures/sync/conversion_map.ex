defmodule Lilac.Sync.Conversion.Map do
  @moduledoc """
  Conversion.Map holds methods to interact with maps
  specialized for converting raw entities' names to their counts

  Structure:
  %{
    artist_name => {
      %{id, playcount, first_scrobbled, last_scrobbled, name},
      %{
        album_name => {
          %{id, playcount, first_scrobbled, last_scrobbled, name},
          %{
            track_name1 => %{id, playcount, first_scrobbled, last_scrobbled, name},
            track_name2 => %{id, playcount, first_scrobbled, last_scrobbled, name},
            ...more tracks
          }
        },
        ...more albums
      }
    }
    ...more artists
  }

  All keys are downcased
  """

  @type conversion_key :: String.t()

  def has_artist?(map, artist) do
    Map.has_key?(map, clean_key(artist))
  end

  def has_album?(map, artist, album) do
    has_artist?(map, artist) and
      map |> Map.get(clean_key(artist)) |> elem(1) |> Map.has_key?(clean_key(album))
  end

  def has_track?(map, artist, album, track) do
    has_album?(map, artist, album) and
      map
      |> Map.get(clean_key(artist))
      |> elem(1)
      |> Map.get(clean_key(album))
      |> elem(1)
      |> Map.has_key?(clean_key(track))
  end

  @spec get_artist_id(map, binary) :: integer | nil
  def get_artist_id(map, artist) do
    map |> Map.get(clean_key(artist), {%{}}) |> elem(0) |> Map.get(:id)
  end

  @spec get_album_id(map, binary, binary) :: integer | nil
  def get_album_id(map, artist, album) do
    map
    |> Map.get(clean_key(artist), {nil, %{}})
    |> elem(1)
    |> Map.get(clean_key(album), {%{}})
    |> elem(0)
    |> Map.get(:id)
  end

  @spec get_track_id(map, binary, binary, binary) :: integer | nil
  def get_track_id(map, artist, album, track) do
    map
    |> Map.get(clean_key(artist), {nil, %{}})
    |> elem(1)
    |> Map.get(clean_key(album), {nil, %{}})
    |> elem(1)
    |> Map.get(clean_key(track), %{})
    |> Map.get(:id)
  end

  @spec increment_artist(map, integer | nil, binary, DateTime.t()) :: no_return()
  def increment_artist(map, artist_id, artist_name, date) do
    key = clean_key(artist_name)

    artist_with_albums = Map.get(map, key)

    case artist_with_albums do
      {artist, albums} ->
        Map.put(map, key, build_nested_value(artist_id, artist_name, date, albums, artist))

      _ ->
        Map.put(map, key, build_nested_value(artist_id, artist_name, date, %{}))
    end
  end

  @spec increment_album(map, integer | nil, binary, binary, DateTime.t()) :: no_return()
  def increment_album(map, album_id, artist_name, album_name, date) do
    artist_key = clean_key(artist_name)
    album_key = clean_key(album_name)

    {artist, albums} = Map.get(map, artist_key)
    album_with_tracks = Map.get(albums, album_key)

    album_value =
      case album_with_tracks do
        {album, tracks} ->
          build_nested_value(album_id, album_name, date, tracks, album)

        _ ->
          build_nested_value(album_id, album_name, date, %{})
      end

    artist_value = {artist, Map.put(albums, album_key, album_value)}

    Map.put(map, artist_key, artist_value)
  end

  @spec increment_track(map, integer | nil, binary, binary, binary, DateTime.t()) :: no_return()
  def increment_track(map, track_id, artist_name, album_name, track_name, date) do
    artist_key = clean_key(artist_name)
    album_key = clean_key(album_name)
    track_key = clean_key(track_name)

    {artist, albums} = Map.get(map, artist_key)
    {album, tracks} = Map.get(albums, album_key)
    track_or_nothing = Map.get(tracks, track_key)

    track_value =
      case track_or_nothing do
        nil ->
          build_unnested_value(track_id, track_name, date)

        track ->
          build_unnested_value(track_id, track_name, date, track)
      end

    album_value = {album, Map.put(tracks, track_key, track_value)}
    artist_value = {artist, Map.put(albums, album_key, album_value)}

    Map.put(map, artist_key, artist_value)
  end

  # Helpers
  @spec clean_key(conversion_key) :: conversion_key
  def clean_key(key) do
    cond do
      is_nil(key) -> ""
      is_bitstring(key) || is_binary(key) -> String.downcase(key)
      true -> key
    end
  end

  @spec build_nested_value(integer, binary, Date.t(), map, map) :: {map, map}
  defp build_nested_value(id, name, date, children, value \\ %{}) do
    {build_unnested_value(id, name, date, value), children}
  end

  @spec build_nested_value(integer, binary, Date.t(), map) :: map
  defp build_unnested_value(id, name, date, value \\ %{}) do
    %{
      id: if(Map.has_key?(value, :id), do: value.id, else: id),
      name: if(Map.has_key?(value, :name), do: value.name, else: name),
      playcount: Map.get(value, :playcount, 0) + 1,
      first_scrobbled: older_date(Map.get(value, :first_scrobbled), date),
      last_scrobbled: newer_date(Map.get(value, :last_scrobbled), date)
    }
  end

  @spec older_date(DateTime.t() | nil, DateTime.t() | nil) :: DateTime.t()
  defp older_date(nil, date2) do
    date2
  end

  defp older_date(date1, nil) do
    date1
  end

  defp older_date(date1, date2) do
    case Date.compare(date1, date2) do
      :gt -> date2
      _ -> date1
    end
  end

  @spec newer_date(DateTime.t() | nil, DateTime.t() | nil) :: DateTime.t()
  defp newer_date(date1, nil) do
    date1
  end

  defp newer_date(nil, date2) do
    date2
  end

  defp newer_date(date1, date2) do
    case Date.compare(date1, date2) do
      :lt -> date2
      _ -> date1
    end
  end
end
