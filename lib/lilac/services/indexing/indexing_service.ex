defmodule Lilac.Services.Indexing do
  alias Lilac.Services.{LastFM, LastFMAPI}

  @spec index(String.t(), number) :: no_return
  def index(username, page \\ 1, retry \\ true) do
    IO.puts("Processing page #{page}...")

    recent_tracks =
      LastFM.recent_tracks(%LastFMAPI.Types.RecentTracksParams{
        username: username,
        page: page,
        limit: 1000
      })

    case recent_tracks do
      {:error, _} ->
        index(username, page, false)

      {:ok, %{body: %{"error" => _error}}} when retry == true ->
        index(username, page, false)

      {:ok, fetched_page} ->
        Lilac.Servers.Converting.convert_page(ConvertingServer, fetched_page.body)

        total_pages =
          fetched_page.body["recenttracks"]["@attr"]["totalPages"] |> String.to_integer()

        unless page >= total_pages, do: index(username, page + 1)
    end
  end
end
