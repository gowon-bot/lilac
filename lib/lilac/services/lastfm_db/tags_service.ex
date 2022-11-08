defmodule Lilac.Services.Tags do
  import Ecto.Query, only: [from: 2]

  alias Lilac.InputParser

  alias Lilac.Tag
  alias Lilac.Artist
  alias Lilac.ArtistTag

  @spec list(%Tag.Filters{}) :: [Tag.t()]
  def list(filters) do
    from(t in Tag,
      as: :tag,
      # ArtistTag
      join: at in ArtistTag,
      as: :artist_tag,
      # Artist
      join: a in Artist,
      as: :artist
    )
    |> parse_tag_filters(filters)
    |> Lilac.Repo.all()
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

  @spec parse_tag_filters(Ecto.Query.t(), Tag.Filters.t()) :: Ecto.Query.t()
  defp parse_tag_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Artist.maybe_artist_inputs(Map.get(filters, :artists))
    |> InputParser.Tag.maybe_tag_inputs(
      Map.get(filters, :inputs),
      Map.get(filters, :match_tags_exactly, false)
    )
  end
end
