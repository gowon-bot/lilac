defmodule Lilac.Indexing do
  import Ecto.Query, only: [from: 2]

  alias Lilac.LastFM

  @spec index(%Lilac.User{}, number) :: no_return
  def index(user, page \\ 1, retry \\ true) do
    if page == 1, do: clear_data(user)

    IO.puts("Processing page #{page}...")

    recent_tracks =
      LastFM.recent_tracks(%LastFM.API.Params.RecentTracks{
        username: Lilac.Requestable.from_user(user),
        page: page,
        limit: 500
      })

    case recent_tracks do
      {:error, _} when retry == true ->
        index(user, page, false)

      {:ok, fetched_page} ->
        Lilac.Servers.Converting.convert_page(ConvertingServer, fetched_page, user)

        unless page >= fetched_page.meta.total_pages, do: index(user, page + 1)
    end
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
end
