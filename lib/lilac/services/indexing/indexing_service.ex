defmodule Lilac.Services.Indexing do
  alias Lilac.Services.{LastFM, LastFMAPI}

  @spec index(String.t(), number) :: no_return
  def index(username, page \\ 1) do
    IO.puts("Processing page #{page}...")

    # TODO: handle errors
    {:ok, fetched_page} =
      LastFM.recent_tracks(%LastFMAPI.Types.RecentTracksParams{
        username: username,
        page: page,
        limit: 1000
      })

    Lilac.Servers.Converting.convert_page(ConvertingServer, fetched_page.body)

    total_pages = fetched_page.body["recenttracks"]["@attr"]["totalPages"] |> String.to_integer()

    unless page >= total_pages, do: index(username, page + 1)
  end
end
