defmodule Lilac.InputParser.Artist do
  import Ecto.Query, only: [where: 3]

  alias Lilac.InputParser
  alias Ecto.Query

  @spec maybe_artist_input(Query.t(), Lilac.Artist.Input.t()) :: Query.t()
  def maybe_artist_input(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name(input)
    end
  end

  @spec maybe_name(Query.t(), Lilac.Artist.Input.t()) :: Query.t()
  defp maybe_name(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query |> where([artist: a], a.name == ^input.name)
    else
      query
    end
  end
end
