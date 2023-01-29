defmodule Lilac.Joiner.Artist do
  import Ecto.Query, only: [join: 5, preload: 3]

  alias Lilac.Artist
  alias Lilac.GraphQLHelpers.{Fields, Introspection}

  @spec maybe_join_tags(
          Ecto.Query.t(),
          Artist.Filters.t() | ArtistCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def maybe_join_tags(query, filters, info, select) do
    if Artist.Filters.has_tags?(filters) ||
         Introspection.has_field?(info, Fields.Artist.tags()) ||
         Introspection.has_field?(info, Fields.Artist.Count.tags()) do
      query
      |> join_tags(select)
    else
      query
    end
  end

  @spec join_tags(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_tags(query, select) do
    joined_query =
      query
      |> join(:left, [artist: a], t in assoc(a, :tags), as: :tag)

    if select do
      joined_query |> preload([tag: t], tags: t)
    else
      joined_query
    end
  end
end
