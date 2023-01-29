defmodule Lilac.Joiner.Album do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.Album
  alias Lilac.GraphQLHelpers.{Fields, Introspection}

  # Conditional methods

  @spec maybe_join_artist(
          Ecto.Query.t(),
          Album.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def maybe_join_artist(query, filters, info, select) do
    if Map.has_key?(Map.get(filters, :album, %{}), :artist) ||
         Introspection.has_field?(info, Fields.Album.artist()) do
      query
      |> join_artist(select)
    else
      query
    end
  end

  # Join methods

  @spec join_artist(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  defp join_artist(query, select) do
    joined_query =
      query
      |> join(:inner, [album: l], a in Lilac.Artist, on: l.artist_id == a.id, as: :artist)

    if select do
      joined_query |> select_merge([artist: a], %{artist: a})
    else
      joined_query
    end
  end
end
