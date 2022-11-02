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

  @spec maybe_artist_inputs(Query.t(), [Lilac.Artist.Input.t()]) :: Query.t()
  def maybe_artist_inputs(query, inputs) do
    if is_nil(inputs) || length(inputs) == 0 do
      query
    else
      input_names =
        inputs
        |> Enum.map(fn input -> Map.get(input, :name) end)
        |> Enum.filter(fn n -> !is_nil(n) end)

      query |> where([artist: a], a.name in ^input_names)
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
