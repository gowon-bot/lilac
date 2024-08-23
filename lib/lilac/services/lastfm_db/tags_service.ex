defmodule Lilac.Services.Tags do
  import Ecto.Query, only: [from: 2, select: 3, order_by: 3]

  alias Lilac.InputParser

  alias Lilac.Tag
  alias Lilac.Artist
  alias Lilac.NestedMap

  @spec list(%Tag.Filters{}) :: [Tag.t()]
  def list(filters) do
    from(t in Tag, as: :tag, group_by: [t.id, t.name])
    |> parse_tag_filters(filters)
    |> select_and_order_by(filters)
    |> Lilac.Repo.all()
  end

  @spec count(%Tag.Filters{}) :: integer
  def count(filters) do
    from(t in Tag, as: :tag, select: count(t.id))
    |> parse_tag_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec fetch_tags_for_artists([Artist.Input.t()]) :: no_return
  def fetch_tags_for_artists(artist_inputs) do
    artist_names = artist_inputs |> Enum.map(fn a -> a.name end) |> Enum.filter(fn a -> a end)

    artists = from(a in Artist, where: a.name in ^artist_names) |> Lilac.Repo.all()

    artists
    |> Enum.filter(fn a -> !a.checked_for_tags end)
    |> Lilac.Parallel.map(fn a -> cache_tags_for_artist(a) end, size: 5)
  end

  @spec cache_tags_for_artist(Artist.t()) :: no_return
  def cache_tags_for_artist(artist) do
    {:ok, artist_info} =
      Lilac.LastFM.artist_info(%Lilac.LastFM.API.Params.ArtistInfo{
        artist: artist.name
      })

    tags = from(t in Lilac.Tag, where: t.name in ^artist_info.tags) |> Lilac.Repo.all()

    tag_artists([artist.id], tags |> Enum.map(fn t -> t.id end), true)
  end

  @spec tag_artists([integer], [integer], boolean) :: no_return
  def tag_artists(artist_ids, tag_ids, marked_as_checked) do
    artist_tags =
      artist_ids
      |> Enum.flat_map(fn artist_id ->
        Enum.map(tag_ids, fn tag_id ->
          %Lilac.ArtistTag{
            artist_id: artist_id,
            tag_id: tag_id
          }
        end)
      end)

    Lilac.Repo.insert_all(
      Lilac.ArtistTag,
      artist_tags |> Enum.map(fn t -> %{artist_id: t.artist_id, tag_id: t.tag_id} end),
      on_conflict: :nothing
    )

    if marked_as_checked, do: from(at in Lilac.ArtistTag, update: [set: [checked_for_tags: true]])
  end

  @spec parse_tag_filters(Query.t(), Tag.Filters.t()) :: Query.t()
  defp parse_tag_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Tag.maybe_artist_inputs(Map.get(filters, :artists))
    |> InputParser.Tag.maybe_tag_inputs(
      Map.get(filters, :inputs),
      Map.get(filters, :match_tags_exactly, false)
    )
  end

  @spec select_and_order_by(Query.t(), Tag.Filters.t()) :: Query.t()
  defp select_and_order_by(query, filters) do
    if Map.has_key?(filters, :artists) do
      query
      |> select([tag: t, artist: a], %{id: t.id, name: t.name, occurrences: count(a.id)})
      |> order_by([tag: t, artist: a], desc: count(a.id), asc: t.name)
    else
      query
      |> select([tag: t], %{id: t.id, name: t.name, occurrences: nil})
      |> order_by([tag: t], asc: t.name)
    end
  end

  defmodule Conversion do
    alias Lilac.NestedMap
    # Tags
    @spec convert_tags([String.t()]) :: map
    def convert_tags(tags) do
      tag_map = generate_tag_map(tags)

      create_missing_tags(tag_map, tags)
    end

    @spec generate_tag_map([String.t()]) :: map
    def generate_tag_map(tags) do
      tags = Enum.uniq(tags)

      query = from(t in Tag, where: t.name in ^tags)

      tags = query |> Lilac.Repo.all()

      add_tags_to_conversion_map(tags, %{})
    end

    @spec create_missing_tags(map, [String.t()]) :: map
    def create_missing_tags(conversion_map, tags) do
      tags = NestedMap.filter_unmapped_keys(conversion_map, Enum.uniq(tags))

      if length(tags) == 0 do
        conversion_map
      else
        new_tags = Enum.map(tags, fn t -> %{name: t} end)

        {_, inserted_tags} = Lilac.Repo.insert_all(Tag, new_tags, returning: true)

        add_tags_to_conversion_map(inserted_tags, conversion_map)
      end
    end

    @spec add_tags_to_conversion_map([Tag.t()], map) :: map
    defp add_tags_to_conversion_map(tags, map) do
      Enum.reduce(
        tags,
        map,
        fn tag, acc -> NestedMap.add(acc, tag.name, tag.id) end
      )
    end
  end
end
