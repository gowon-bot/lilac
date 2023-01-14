defmodule Lilac.Services.Indexing do
  import Ecto.Query, only: [from: 2]

  alias Lilac.LastFM
  alias Lilac.LastFM.API.Params
  alias Lilac.LastFM.Responses

  @spec index(%Lilac.User{}) :: no_return
  def index(user) do
    clear_data(user)

    convert_pages(
      user,
      %Params.RecentTracks{
        username: Lilac.Requestable.from_user(user),
        limit: 500
      },
      :indexing
    )
  end

  @spec update(%Lilac.User{}) :: no_return
  def update(user) do
    if user.last_indexed == nil do
      index(user)
    else
      convert_pages(
        user,
        %Params.RecentTracks{
          username: Lilac.Requestable.from_user(user),
          limit: 500,
          from: DateTime.to_unix(user.last_indexed) + 1
        },
        :updating
      )
    end
  end

  @spec convert_pages(
          %Lilac.User{},
          %Params.RecentTracks{},
          Lilac.IndexingSupervisor.action()
        ) :: no_return()
  defp convert_pages(user, params, action) do
    fetched_page = fetch_page(user, %{params | page: 1})

    case fetched_page do
      {:error, _error} ->
        shutdown_subscription(params, user)

      {:ok, %Responses.RecentTracks{meta: %Responses.RecentTracks.Meta{total_pages: 0}}} ->
        shutdown_subscription(params, user)

      {:ok, page} ->
        Lilac.IndexingSupervisor.spin_up_servers(user, action)

        total_pages = page.meta.total_pages

        first_scrobble =
          if Enum.at(page.tracks, 0).is_now_playing,
            do: Enum.at(page.tracks, 1),
            else: Enum.at(page.tracks, 0)

        user =
          Ecto.Changeset.change(user, last_indexed: first_scrobble.scrobbled_at)
          |> Lilac.Repo.update!()

        Enum.each(1..total_pages, fn page_number ->
          Lilac.IndexingProgressServer.add_page(user, page_number)
        end)

        Lilac.Parallel.map(
          1..total_pages,
          fn page_number ->
            fetched_page = fetch_page(user, %{params | page: page_number})

            case fetched_page do
              {:ok, page} ->
                Lilac.ConvertingServer.convert_page(
                  user,
                  page
                )

              {:error, error} ->
                IO.puts("An error occurred while indexing: #{inspect(error)}")
            end
          end,
          size: 5
        )
    end
  end

  @spec shutdown_subscription(Lilac.LastFM.API.Params.RecentTracks.t(), Lilac.User.t()) ::
          no_return
  defp shutdown_subscription(params, user) do
    # Give the client a chance to form the subscription
    Process.sleep(300)

    Lilac.IndexingProgressServer.update_subscription(
      if(is_nil(params.from), do: :indexing, else: :updating),
      0,
      0,
      user.id
    )

    Lilac.IndexingSupervisor.self_destruct(user)
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

  @spec fetch_page(%Lilac.User{}, %Params.RecentTracks{}, integer) ::
          {:ok, %Responses.RecentTracks{}} | {:error, struct}
  defp fetch_page(user, params, retries \\ 1) do
    recent_tracks = LastFM.recent_tracks(params)

    case recent_tracks do
      {:error, _} when retries <= 3 ->
        # Wait 300ms before trying again
        Process.sleep(300)
        fetch_page(user, params, retries + 1)

      response ->
        response
    end
  end
end
