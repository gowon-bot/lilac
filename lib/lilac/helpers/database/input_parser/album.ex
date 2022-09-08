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
end
