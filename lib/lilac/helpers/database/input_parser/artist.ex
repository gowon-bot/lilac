defmodule Lilac.InputParser.Artist do
  import Ecto.Query, only: [where: 3, from: 2, select: 3]

  alias Lilac.Artist

  alias Lilac.InputParser
  alias Ecto.Query

  @spec maybe_artist_input(Query.t(), Artist.Input.t()) :: Query.t()
  def maybe_artist_input(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name(input)
    end
  end

  @spec maybe_name(Query.t(), Artist.Input.t()) :: Query.t()
  defp maybe_name(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query |> where([artist: a], a.name == ^input.name)
    else
      query
    end
  end

  @spec maybe_tag_inputs(Query.t(), [Lilac.Tag.Input.t()], boolean) :: Query.t()
  def maybe_tag_inputs(query, inputs, match_exactly) do
    if is_nil(inputs) || length(inputs) == 0 do
      query
    else
      tag_names = InputParser.Tag.generate_tag_names(inputs)

      tags_subquery =
        if(match_exactly,
          do: from(t in Lilac.Tag, where: t.name in ^tag_names),
          else:
            from(t in Lilac.Tag,
              as: :tag,
              where: ^InputParser.Tag.matches_tags_condition(tag_names)
            )
        )
        |> select([t], t.id)

      artist_tags_subquery =
        from(at in Lilac.ArtistTag, where: at.tag_id in subquery(tags_subquery))
        |> select([at], at.artist_id)

      query |> where([artist: a], a.id in subquery(artist_tags_subquery))
    end
  end

  @spec maybe_in_artist_list(Ecto.Query.t(), %Artist.Filters{}, %Lilac.Tag.Filters{}) ::
          Ecto.Query.t()
  def maybe_in_artist_list(query, inputs, tags) do
    if !is_nil(inputs) || !is_nil(tags) do
      artist_filters = %{tags: tags, inputs: inputs}

      artist_ids =
        Lilac.Services.Artists.list(artist_filters, %Absinthe.Resolution{})
        |> Enum.map(fn a -> a.id end)

      query |> where([artist_count: ac], ac.artist_id in ^artist_ids)
    else
      query
    end
  end

  @spec maybe_artist_inputs(Query.t(), [Artist.Input.t()]) :: Query.t()
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

  @spec maybe_artist_input_for_rym(Query.t(), Artist.Input.t()) :: Query.t()
  def maybe_artist_input_for_rym(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_name_for_rym(input)
    end
  end

  @spec maybe_name_for_rym(Query.t(), Artist.Input.t()) :: Query.t()
  defp maybe_name_for_rym(query, input) do
    if InputParser.value_not_nil(input, :name) do
      query
      |> where(
        [rate_your_music_album: rl],
        ilike(rl.artist_name, ^InputParser.escape_like(input.name)) or
          ilike(rl.artist_native_name, ^InputParser.escape_like(input.name))
      )
    else
      query
    end
  end
end
