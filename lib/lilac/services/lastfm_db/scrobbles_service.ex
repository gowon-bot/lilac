defmodule Lilac.Services.Scrobbles do
  import Ecto.Query, only: [from: 2, from: 1, join: 5, select_merge: 3, select: 3]

  alias Lilac.{InputParser, Joiner}
  alias Lilac.Scrobble
  alias Lilac.GraphQLHelpers.{Introspection, Fields}

  @spec list(Scrobble.Filters.t(), Absinthe.Resolution.t()) :: [Scrobble.t()]
  def list(filters, info) do
    from(s in Lilac.Scrobble,
      order_by: [desc: s.scrobbled_at],
      select_merge: s
    )
    |> generate_joins(filters, info)
    |> parse_scrobble_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Scrobble.Filters.t()) :: integer
  def count(filters) do
    from(s in Scrobble)
    |> generate_joins(filters, %Absinthe.Resolution{}, false)
    |> parse_scrobble_filters(filters |> Map.put(:pagination, nil))
    |> select([], count())
    |> Lilac.Repo.one()
  end

  @spec parse_scrobble_filters(Ecto.Query.t(), Scrobble.Filters.t()) :: Ecto.Query.t()
  defp parse_scrobble_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_input(Map.get(filters, :user))
    |> InputParser.Artist.maybe_artist_input(Map.get(filters, :artist))
    |> InputParser.Album.maybe_album_input(Map.get(filters, :album))
    |> InputParser.Track.maybe_track_input(Map.get(filters, :track))
  end

  @spec generate_joins(
          Ecto.Query.t(),
          Scrobble.Filters.t(),
          %Absinthe.Resolution{},
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins(query, filters, info, select \\ true) do
    query
    |> Joiner.Scrobble.chained_maybe_join_track(filters, info, select)
    |> Joiner.Scrobble.maybe_join_user(filters, info, select)
  end
end
