defmodule Lilac.Services.Tracks do
  import Ecto.Query, only: [from: 2]

  alias Lilac.{TrackCount, Track}
  alias Lilac.{InputParser, Joiner}

  @spec list(Track.Filters.t(), %Absinthe.Resolution{}) :: [Track.t()]
  def list(filters, info) do
    from(t in Track, as: :track)
    |> generate_joins(filters, info)
    |> parse_track_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count(Track.Filters.t()) :: integer
  def count(filters) do
    from(t in Track, as: :track, select: count())
    |> parse_track_filters(filters |> Map.put(:pagination, nil))
    |> generate_joins(filters, %Absinthe.Resolution{})
    |> Lilac.Repo.one()
  end

  @spec list_counts(TrackCount.Filters.t(), Absinthe.Resolution.t()) :: [TrackCount.t()]
  def list_counts(filters, info) do
    from(tc in TrackCount,
      as: :track_count,
      order_by: [desc: :playcount]
    )
    |> generate_joins_for_counts(filters, info)
    |> parse_track_count_filters(filters)
    |> Lilac.Repo.all()
  end

  @spec count_counts(TrackCount.Filters.t()) :: integer
  def count_counts(filters) do
    from(ac in TrackCount, as: :track_count, select: count(ac.id))
    |> generate_joins_for_counts(filters, %Absinthe.Resolution{}, false)
    |> parse_track_count_filters(filters)
    |> Lilac.Repo.one()
  end

  @spec generate_joins(
          Ecto.Query.t(),
          Track.Filters.t(),
          %Absinthe.Resolution{},
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins(query, filters, info, select \\ true) do
    query
    |> Joiner.Track.chained_maybe_join_album(filters, info, select)
  end

  @spec generate_joins_for_counts(
          Ecto.Query.t(),
          TrackCount.Filters.t(),
          %Absinthe.Resolution{},
          boolean | nil
        ) ::
          Ecto.Query.t()
  defp generate_joins_for_counts(query, filters, info, select \\ true) do
    query
    |> Joiner.TrackCount.chained_maybe_join_album(filters, info, select)
    |> Joiner.TrackCount.maybe_join_user(filters, info, select)
  end

  @spec parse_track_count_filters(Ecto.Query.t(), TrackCount.Filters.t()) :: Ecto.Query.t()
  defp parse_track_count_filters(query, filters) do
    query
    |> parse_track_filters(filters)
    |> InputParser.User.maybe_user_inputs(Map.get(filters, :users))
  end

  @spec parse_track_filters(Ecto.Query.t(), Track.Filters.t()) :: Ecto.Query.t()
  defp parse_track_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.Track.maybe_track_input(Map.get(filters, :track))
  end
end
