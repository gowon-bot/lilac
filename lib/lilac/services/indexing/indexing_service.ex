defmodule Lilac.Indexing do
  import Ecto.Query, only: [from: 2]

  alias Lilac.LastFM
  alias Lilac.LastFM.API.Params

  @spec index(%{converting: pid, indexing_progress: pid}, %Lilac.User{}) :: no_return
  def index(pids, user) do
    clear_data(user)

    convert_pages(pids, user, %Params.RecentTracks{
      username: Lilac.Requestable.from_user(user),
      limit: 500
    })
  end

  @spec update(%{converting: pid, indexing_progress: pid}, %Lilac.User{}) :: no_return
  def update(pids, user) do
    if user.last_indexed == nil do
      index(pids, user)
    else
      convert_pages(
        pids,
        user,
        %Params.RecentTracks{
          username: Lilac.Requestable.from_user(user),
          limit: 500,
          from: DateTime.to_unix(user.last_indexed) + 1
        }
      )
    end
  end

  @spec convert_pages(
          %{converting: pid, indexing_progress: pid},
          %Lilac.User{},
          %Params.RecentTracks{}
        ) :: no_return()
  defp convert_pages(pids, user, params) do
    page = fetch_page(user, %{params | page: 1})

    total_pages = page.meta.total_pages

    first_scrobble =
      if Enum.at(page.tracks, 0).is_now_playing,
        do: Enum.at(page.tracks, 1),
        else: Enum.at(page.tracks, 0)

    user =
      Ecto.Changeset.change(user, last_indexed: first_scrobble.scrobbled_at)
      |> Lilac.Repo.update!()

    Enum.each(1..total_pages, fn page_number ->
      Lilac.Servers.IndexingProgress.add_page(pids.indexing_progress, page_number)
    end)

    Lilac.Parallel.map(
      1..total_pages,
      fn page_number ->
        page = fetch_page(user, %{params | page: page_number})

        Lilac.Servers.Converting.convert_page(
          pids.converting,
          page,
          user,
          pids.indexing_progress
        )
      end,
      size: 5
    )
  end

  @spec clear_data(%Lilac.User{}) :: no_return()
  defp clear_data(user) do
    Enum.each(
      [Lilac.Scrobble, Lilac.ArtistCount, Lilac.AlbumCount, Lilac.TrackCount],
      fn elem ->
        from(e in elem, where: e.user_id == ^user.id) |> Lilac.Repo.delete_all()
      end
    )
  end

  @spec fetch_page(%Lilac.User{}, %Params.RecentTracks{}, boolean) ::
          %LastFM.Responses.RecentTracks{}
  defp fetch_page(user, params, retry \\ true) do
    recent_tracks = LastFM.recent_tracks(params)

    case recent_tracks do
      {:error, _} when retry == true ->
        fetch_page(user, params, false)

      {:error, error} ->
        error

      {:ok, fetched_page} ->
        fetched_page
    end
  end
end
