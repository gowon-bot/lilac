defmodule Lilac.Sync.Fetcher do
  use GenServer

  alias Lilac.Sync
  alias Lilac.Sync.Registry

  alias Lilac.LastFM.API.Params
  alias Lilac.LastFM.Responses

  @spec start_link(Lilac.User.t()) :: {:ok, pid} | {:error, term}
  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.fetcher(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user, params: nil, total_pages: nil}}
  end

  @spec start_sync(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def start_sync(user) do
    GenServer.cast(Registry.fetcher(user), :sync)
    {:ok, nil}
  end

  @spec start_update(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def start_update(user) do
    GenServer.cast(Registry.fetcher(user), :update)
    {:ok, nil}
  end

  ## Server callbacks

  @impl true
  @spec handle_cast(:sync, %{user: Lilac.User.t()}) :: {:noreply, map}
  def handle_cast(:sync, state) do
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
  @spec handle_cast(:update, %{user: Lilac.User.t()}) :: {:noreply, map}
  def handle_cast(:update, state) do
    unless state.user.last_synced == nil do
      params = %Params.RecentTracks{
        username: Lilac.Requestable.from_user(state.user),
        limit: 500,
        from: DateTime.to_unix(state.user.last_synced) + 1
      }

      total_pages =
        initial_fetch(
          state.user,
          params,
          :update
        )

      {:noreply, %{state | params: params, total_pages: total_pages}}
    else
      start_sync(state.user)

      {:noreply, state}
    end
  end

  @spec initial_fetch(
          Lilac.User.t(),
          Params.RecentTracks.t(),
          Lilac.Sync.Supervisor.action(),
          integer
        ) :: integer()
  defp initial_fetch(user, params, action, start_page \\ 1) do
    case fetch_page(user, %{params | page: start_page}) do
      {:error, error} ->
        Sync.Subscriptions.report_error(action, user, error)
        0

      {:ok, %Responses.RecentTracks{meta: %Responses.RecentTracks.Meta{total_pages: 0}}} ->
        Sync.Subscriptions.terminate(action, user)
        0

      {:ok, page} ->
        continue_fetching(user, action, page, params)
    end
  end

  @spec continue_fetching(
          Lilac.User.t(),
          Lilac.Sync.Supervisor.action(),
          %Responses.RecentTracks{},
          %Params.RecentTracks{}
        ) :: integer()
  defp continue_fetching(user, action, page, params) do
    Sync.Supervisor.spin_up_servers(user, action)

    total_pages = page.meta.total_pages

    first_scrobble =
      if Enum.at(page.tracks, 0).is_now_playing,
        do: Enum.at(page.tracks, 1),
        else: Enum.at(page.tracks, 0)

    user =
      Ecto.Changeset.change(user, last_synced: first_scrobble.scrobbled_at)
      |> Lilac.Repo.update!()

    Sync.ProgressReporter.set_total(user, :fetching, page.meta.total)

    fetch_all_pages(user, params, total_pages, action)

    total_pages
  end

  @spec fetch_all_pages(
          Lilac.User.t(),
          Params.RecentTracks.t(),
          integer,
          Lilac.Sync.Supervisor.action()
        ) :: no_return()
  defp fetch_all_pages(user, params, total_pages, action) do
    Lilac.Parallel.map(
      1..total_pages,
      fn page_number ->
        IO.puts("Fetching page #{page_number}...")

        fetched_page = fetch_page(user, %{params | page: page_number})

        case fetched_page do
          {:ok, page} ->
            Sync.Converter.process_page(
              user,
              page,
              action
            )

          {:error, error} ->
            # Because this is being processed in parallel, we need to report the error
            # as a message to the converting server. This way, race conditions are avoided,
            # and the error is handled in the correct order.
            Sync.Converter.fetch_error(action, user, error)
        end
      end,
      size: 4
    )
  end

  @spec fetch_page(Lilac.User.t(), Params.RecentTracks.t(), integer) ::
          {:ok, Responses.RecentTracks.t()} | {:error, struct}
  def fetch_page(user, params, retries \\ 1) do
    case Lilac.LastFM.recent_tracks(params) do
      {:error, _} when retries <= 3 ->
        # Exponential backoff
        Process.sleep(retries * retries * 2000)
        fetch_page(user, params, retries + 1)

      response ->
        response
    end
  end
end
