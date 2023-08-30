defmodule Lilac.Joiner.Track do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.Track
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  # Conditional methods

  @spec chained_maybe_join_album(
          Ecto.Query.t(),
          Track.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  def chained_maybe_join_album(query, filters, info, select) do
    if Track.Filters.has_album?(filters) ||
         Introspection.has_field?(info, Fields.Track.album()) do
      query
      |> join_artist(select)
      |> join_album(select)
    else
      query |> maybe_join_artist(filters, info, select)
    end
  end

  @spec maybe_join_artist(
          Ecto.Query.t(),
          Track.Filters.t(),
          %Absinthe.Resolution{},
          boolean
        ) ::
          Ecto.Query.t()
  defp maybe_join_artist(query, filters, info, select) do
    if Track.Filters.has_artist?(filters) ||
         Introspection.has_field?(info, Fields.Track.artist()) do
      query
      |> join_artist(select)
    else
      query
    end
  end

  # Join methods

  @spec join_album(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  def join_album(query, select) do
    joined_query =
      query
      |> join(:inner, [track: t], l in Lilac.Album, on: t.album_id == l.id, as: :album)

    if select do
      joined_query
      |> select_merge([album: l, artist: a], %{album: l, artist: a})
    else
      joined_query
    end
  end

  @spec join_artist(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  def join_artist(query, select) do
    joined_query =
      query
      |> join(:inner, [track: t], a in Lilac.Artist, on: t.artist_id == a.id, as: :artist)

    if select do
      joined_query |> select_merge([artist: a], %{ artist: a})
    else
      joined_query
    end
  end
end
