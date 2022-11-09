defmodule LilacWeb.Resolvers.Tags do
  alias Lilac.Tag
  alias Lilac.Services.Tags

  @spec tagArtists(
          any,
          %{artists: [Lilac.Artist.Input.t()], tags: [Tag.t()], mark_as_checked: boolean},
          any
        ) :: {:ok, any}
  def tagArtists(_root, %{artists: artists, tags: tags, mark_as_checked: mark_as_checked}, _info) do
    artists = Lilac.Converting.convert_artists(Enum.map(artists, fn a -> a.name end))
    tags = Lilac.Converting.convert_tags(Enum.map(tags, fn t -> t.name end))

    Tags.tag_artists(Map.values(artists), Map.values(tags), mark_as_checked)

    {:ok, nil}
  end

  @spec list(any, %{filters: Tag.Filters.t()}, any) :: {:ok, any}
  def list(_root, %{filters: filters}, _info) do
    if Map.get(filters, :fetch_tags_for_missing, false) == true and
         length(Map.get(filters, :artists, [])) > 0 do
      Tags.fetch_tags_for_artists(Map.get(filters, :artists))
    end

    tags = Tags.list(filters)

    {:ok,
     %Tag.Page{
       tags: tags,
       pagination: Lilac.Pagination.generate(Tags.count(filters), Map.get(filters, :pagination))
     }}
  end
end
