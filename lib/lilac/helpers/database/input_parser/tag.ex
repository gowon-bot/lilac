defmodule Lilac.InputParser.Tag do
  import Ecto.Query, only: [where: 3, dynamic: 2, dynamic: 1, join: 5]

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

      dynamic([tag: t], ^acc or fragment("? ~* ?", t.name, ^regex))
    end)
  end

  @spec generate_tag_regex(binary) :: binary
  defp generate_tag_regex(tag_name) do
    cleaned = Regex.replace(~r/(\s+|-|_)/, tag_name, "")

    cleaned
    |> String.split("")
    |> Enum.map(fn char -> char <> "(\\s+|-|_)?" end)
    |> Enum.join("")
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

      query
      |> join(:left, [tag: t], at in Lilac.ArtistTag, as: :artist_tag, on: at.tag_id == t.id)
      |> join(:left, [tag: t, artist_tag: at], a in Lilac.Artist,
        as: :artist,
        on: a.id == at.artist_id
      )
      |> where([artist: a], a.name in ^input_names)
    end
  end
end
