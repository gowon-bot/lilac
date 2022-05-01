defmodule Lilac.Indexing do
  import Ecto.Query, only: [from: 2]

  alias Lilac.LastFM
  alias Lilac.LastFM.API.Params

  @spec index(pid, %Lilac.User{}) :: no_return
  def index(converting_pid, user) do
    clear_data(user)

    page = fetch_page(user, 1)

    total_pages = page.meta.total_pages

    Lilac.Parallel.map(
      2..total_pages,
      fn page_number ->
        page = fetch_page(user, page_number)

        Lilac.Servers.Converting.convert_page(converting_pid, page, user)
      end,
      size: 5
    )
  end

  @spec clear_data(%Lilac.User{}) :: no_return()
  def clear_data(user) do
    Enum.each(
      [Lilac.Scrobble, Lilac.ArtistCount, Lilac.AlbumCount, Lilac.TrackCount],
      fn elem ->
        from(e in elem, where: e.user_id == ^user.id) |> Lilac.Repo.delete_all()
      end
    )
  end

  @spec fetch_page(%Lilac.User{}, integer, boolean) :: %LastFM.Responses.RecentTracks{}
  defp fetch_page(user, page, retry \\ true) do
    params = %Params.RecentTracks{
      username: Lilac.Requestable.from_user(user),
      page: page,
      limit: 500
    }

    recent_tracks = LastFM.recent_tracks(params)

    IO.puts("Fetched page #{page}...")

    case recent_tracks do
      {:error, _} when retry == true ->
        fetch_page(user, page, false)

      {:error, error} ->
        error

      {:ok, fetched_page} ->
        fetched_page
    end
  end
end
