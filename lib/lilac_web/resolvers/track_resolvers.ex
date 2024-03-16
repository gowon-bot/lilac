defmodule LilacWeb.Resolvers.Tracks do
  alias Lilac.{Track, TrackCount}
  alias Lilac.Services

  @spec list(any, %{filters: Track.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, Track.Page.t()}
  def list(_root, %{filters: filters}, info) do
    tracks = Services.Tracks.list(filters, info)

    {:ok, Track.Page.generate(tracks, info, filters)}
  end

  @spec list_ambiguous(any, %{filters: Track.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, Track.Ambiguous.Page.t()}
  def list_ambiguous(_root, %{filters: filters}, info) do
    tracks = Services.Tracks.list_ambiguous(filters, info)

    {:ok, Track.Ambiguous.Page.generate(tracks, info, filters)}
  end

  @spec list_counts(any, %{filters: TrackCount.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, TrackCount.Page.t()}
  def list_counts(_root, %{filters: filters}, info) do
    track_counts = Services.Tracks.list_counts(filters, info)

    {:ok, TrackCount.Page.generate(track_counts, info, filters)}
  end

  @spec list_ambiguous_counts(any, %{filters: TrackCount.Filters.t()}, Absinthe.Resolution.t()) ::
          {:ok, TrackCount.Ambiguous.Page.t()}
  def list_ambiguous_counts(_root, %{filters: filters}, info) do
    track_counts = Services.Tracks.list_ambiguous_counts(filters, info)

    {:ok, TrackCount.Ambiguous.Page.generate(track_counts, info, filters)}
  end
end
