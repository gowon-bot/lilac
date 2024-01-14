defmodule Lilac.Sync.Fetcher do
  use GenServer

  alias Lilac.Sync
  alias Lilac.Sync.Registry

  alias Lilac.LastFM.API.Params
  alias Lilac.LastFM.Responses

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.fetcher(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user, params: nil, total_pages: nil}}
  end

  @spec start_sync(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def start_sync(user) do
    GenServer.cast(Registry.fetcher(user), {:sync})
    {:ok, nil}
  end

  @spec start_sync_update(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def start_sync_update(user) do
    GenServer.cast(Registry.fetcher(user), {:sync_update})
    {:ok, nil}
  end

  ## Server callbacks

  @impl true
  def handle_cast({:sync}, state) do
    Sync.Dataset.clear(state.user)

    params = %Params.RecentTracks{
      username: Lilac.Requestable.from_user(state.user),
      limit: 1000
    }

    total_pages =
      initial_fetch(
        state.user,
        params,
        :sync
      )

    {:noreply, %{state | params: params, total_pages: total_pages}}
  end

  @impl true
  def handle_cast({:sync_update}, state) do
    unless state.user.last_indexed == nil do
      params = %Params.RecentTracks{
        username: Lilac.Requestable.from_user(state.user),
        limit: 500,
        from: DateTime.to_unix(state.user.last_indexed) + 1
      }

      total_pages =
        initial_fetch(
          state.user,
          params,
          :sync_update
        )

      {:noreply, %{state | params: params, total_pages: total_pages}}
    else
      start_sync(state.user)

      {:noreply, state}
    end
  end

  @spec initial_fetch(
          %Lilac.User{},
          %Params.RecentTracks{},
          Lilac.Sync.Supervisor.action(),
          integer
        ) :: integer()
  defp initial_fetch(user, params, action, start_page \\ 1) do
    case fetch_page(user, %{params | page: start_page}) do
      {:error, _error} ->
        Sync.Subscriptions.terminate(params, user)
        0

      {:ok, %Responses.RecentTracks{meta: %Responses.RecentTracks.Meta{total_pages: 0}}} ->
        Sync.Subscriptions.terminate(params, user)
        0

      {:ok, page} ->
        continue_fetching(user, action, page, params)
    end
  end

  defp continue_fetching(user, action, page, params) do
    Sync.Supervisor.spin_up_servers(user, action)

    total_pages = page.meta.total_pages

    first_scrobble =
      if Enum.at(page.tracks, 0).is_now_playing,
        do: Enum.at(page.tracks, 1),
        else: Enum.at(page.tracks, 0)

    user =
      Ecto.Changeset.change(user, last_indexed: first_scrobble.scrobbled_at)
      |> Lilac.Repo.update!()

    Sync.ProgressReporter.set_total(user, :fetching, page.meta.total)

    fetch_all_pages(user, params, total_pages)

    total_pages
  end

  defp fetch_all_pages(user, params, total_pages) do
    Lilac.Parallel.map(
      1..total_pages,
      fn page_number ->
        IO.puts("Fetching page #{page_number}...")

        fetched_page = fetch_page(user, %{params | page: page_number})

        case fetched_page do
          {:ok, page} ->
            Sync.Converter.process_page(
              user,
              page
            )

          {:error, error} ->
            IO.puts("An error occurred while syncing: #{inspect(error)}")
        end
      end,
      size: 5
    )
  end

  @spec fetch_page(Lilac.User.t(), Params.RecentTracks.t(), integer) ::
          {:ok, Responses.RecentTracks.t()} | {:error, struct}
  def fetch_page(user, params, retries \\ 1) do
    case Lilac.LastFM.recent_tracks(params) do
      {:error, _} when retries <= 3 ->
        # Wait 300ms before trying again
        Process.sleep(300)
        fetch_page(user, params, retries + 1)

      response ->
        response
    end
  end
end
