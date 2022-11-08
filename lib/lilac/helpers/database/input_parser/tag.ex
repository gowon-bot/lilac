defmodule Lilac.InputParser.Tag do
  import Ecto.Query, only: [where: 3, dynamic: 2, dynamic: 1]

  alias Ecto.Query

  @spec maybe_tag_inputs(Query.t(), [Lilac.Tag.Input.t()], boolean) :: Query.t()
  def maybe_tag_inputs(query, inputs, match_exactly) do
    if is_nil(inputs) || length(inputs) == 0 do
      query
    else
      tag_names = generate_tag_names(inputs)

      if match_exactly do
        query |> where([tag: t], t.name in ^tag_names)
      else
        query |> where([tag: t], ^matches_tags_condition(tag_names))
      end
    end
  end

  @spec generate_tag_names([Lilac.Tag.Input.t()]) :: [binary]
  def generate_tag_names(inputs) do
    inputs
    |> Enum.map(fn input -> Map.get(input, :name) end)
    |> Enum.filter(fn n -> !is_nil(n) end)
  end

  @spec matches_tags_condition([binary]) :: Macro.t()
  def matches_tags_condition(tag_names) do
    tag_names
    |> Enum.reduce(dynamic(false), fn tag, acc ->
      regex = "^#{generate_tag_regex(tag)}$"

      dynamic([tag: t], ^acc or fragment("? ~ ?", t.name, ^regex))
    end)
  end

  @spec generate_tag_regex(binary) :: binary
  defp generate_tag_regex(tag_name) do
    Regex.replace(~r/(\\s+|-|_)/i, tag_name, "(\\s+|-|_)?")
  end
end
