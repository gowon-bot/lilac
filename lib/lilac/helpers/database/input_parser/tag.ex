defmodule Lilac.InputParser.Tag do
  import Ecto.Query, only: [where: 3, dynamic: 2, dynamic: 1, from: 2, select: 3]

  alias Ecto.Query

  @spec maybe_tag_inputs(Query.t(), [Lilac.Tag.Input.t()], boolean) :: Query.t()
  def maybe_tag_inputs(query, inputs, match_exactly) do
    if is_nil(inputs) || length(inputs) == 0 do
      query
    else
      tag_names = generate_tag_names(inputs)

      tags_subquery =
        if(match_exactly,
          do: from(t in Lilac.Tag, where: t.name in ^tag_names),
          else: from(t in Lilac.Tag, as: :tag, where: ^matches_tags_condition(tag_names))
        )
        |> select([t], t.id)

      artist_tags_subquery =
        from(at in Lilac.ArtistTag, where: at.tag_id in subquery(tags_subquery))
        |> select([at], at.artist_id)

      query |> where([artist: a], a.id in subquery(artist_tags_subquery))
    end
  end

  @spec generate_tag_names([Lilac.Tag.Input.t()]) :: [binary]
  defp generate_tag_names(inputs) do
    inputs
    |> Enum.map(fn input -> Map.get(input, :name) end)
    |> Enum.filter(fn n -> !is_nil(n) end)
  end

  @spec matches_tags_condition([binary]) :: Macro.t()
  defp matches_tags_condition(tag_names) do
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
