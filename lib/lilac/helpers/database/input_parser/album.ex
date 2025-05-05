defmodule Lilac.InputParser.Album do
  import Ecto.Query, only: [where: 3]

  alias Lilac.InputParser
  alias Ecto.Query

  @spec maybe_album_input(Query.t(), Lilac.Album.Input.t()) :: Query.t()
  def maybe_album_input(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name(input)
      |> InputParser.Artist.maybe_artist_input(Map.get(input, :artist))
    end
  end

  @spec maybe_name(Query.t(), Lilac.Album.Input.t()) :: Query.t()
  defp maybe_name(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query
      |> where(
        [album: a],
        a.name == ^input.name or (^(input.name == "") and is_nil(a.name))
      )
    else
      query
    end
  end

  @spec maybe_album_input_for_rym(Query.t(), Lilac.Album.Input.t()) :: Query.t()
  def maybe_album_input_for_rym(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name_for_rym(input)
      |> InputParser.Artist.maybe_artist_input_for_rym(Map.get(input, :artist))
    end
  end

  @spec maybe_name_for_rym(Query.t(), Lilac.Album.Input.t()) :: Query.t()
  defp maybe_name_for_rym(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query
      |> where(
        [rate_your_music_album: rl],
        ilike(rl.title, ^InputParser.escape_like(input.name))
      )
    else
      query
    end
  end
end
