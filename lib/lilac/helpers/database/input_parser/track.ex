defmodule Lilac.InputParser.Track do
  import Ecto.Query, only: [where: 3]

  alias Lilac.InputParser
  alias Ecto.Query

  @spec maybe_track_input(Query.t(), Lilac.Track.Input.t()) :: Query.t()
  def maybe_track_input(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name(input)
      |> InputParser.Artist.maybe_artist_input(Map.get(input, :artist))
      |> InputParser.Album.maybe_album_input(Map.get(input, :album))
    end
  end

  @spec maybe_name(Query.t(), Lilac.Track.Input.t()) :: Query.t()
  defp maybe_name(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query |> where([track: t], t.name == ^input.name)
    else
      query
    end
  end
end
