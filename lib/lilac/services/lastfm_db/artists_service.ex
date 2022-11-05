defmodule Lilac.Services.Artists do
  import Ecto.Query, only: [from: 2]

  alias Lilac.InputParser
  alias Lilac.Artist

  @spec list(Artist.Filters.t()) :: [Artist.t()]
  def list(filters) do
    from(a in Artist, as: :artist, preload: :tags)
    |> parse_artist_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Artist.Filters.t()) :: integer
  def count(filters) do
    from(a in Artist, as: :artist, select: count())
    |> parse_artist_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec parse_artist_filters(Ecto.Query.t(), Artist.Filters.t()) :: Ecto.Query.t()
  defp parse_artist_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Artist.maybe_artist_inputs(Map.get(filters, :inputs))
    |> InputParser.Tag.maybe_tag_inputs(
      Map.get(filters, :tags),
      Map.get(filters, :match_tags_exactly, false)
    )
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

    tag_artists([artist], tags)
  end

  @spec tag_artists([Artist.t()], [Lilac.Tag.t()]) :: no_return
  def tag_artists(artists, tags) do
    artist_tags =
      artists
      |> Enum.flat_map(fn a ->
        Enum.map(tags, fn t ->
          %Lilac.ArtistTag{
            artist: a,
            artist_id: a.id,
            tag: t,
            tag_id: t.id
          }
        end)
      end)

    Lilac.Repo.insert_all(
      Lilac.ArtistTag,
      artist_tags |> Enum.map(fn t -> %{artist_id: t.artist_id, tag_id: t.tag_id} end),
      on_conflict: :nothing
    )

    from(at in Lilac.ArtistTag, update: [set: [checked_for_tags: true]])
  end
end
