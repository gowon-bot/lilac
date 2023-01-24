defmodule Lilac.IndexingServer do
  use GenServer

  alias Lilac.IndexerRegistry
  alias Lilac.Services.Indexing

  alias Lilac.LastFM.API.Params
  alias Lilac.LastFM.Responses

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: IndexerRegistry.indexing_server_name(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user, params: nil, last_indexed_page: nil, total_pages: nil, paused: false}}
  end

  @spec index_user(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def index_user(user) do
    GenServer.cast(IndexerRegistry.indexing_server_name(user), {:index})
    {:ok, nil}
  end

  @spec update_user(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def update_user(user) do
    GenServer.cast(IndexerRegistry.indexing_server_name(user), {:update})
    {:ok, nil}
  end

  def pause_page_fetching(user) do
    GenServer.cast(IndexerRegistry.indexing_server_name(user), {:pause_page_fetching})
    {:ok, nil}
  end

  def resume_page_fetching(user) do
    GenServer.cast(IndexerRegistry.indexing_server_name(user), {:resume_page_fetching})
    {:ok, nil}
  end

  ## Server callbacks

  def handle_cast({:pause_page_fetching}, state) do
    {:noreply, %{state | paused: true}}
  end

  def handle_cast({:resume_page_fetching}, state) do
    if state.paused do
      GenServer.cast(
        self(),
        {:index_page, state.last_indexed_page + 1, state.total_pages, state.params}
      )
    end

    {:noreply, %{state | paused: false}}
  end

  @impl true
  def handle_cast({:index}, state) do
    Indexing.clear_data(state.user)

    params = %Params.RecentTracks{
      username: Lilac.Requestable.from_user(state.user),
      limit: 500
    }

    total_pages =
      initialize_index(
        state.user,
        params,
        :indexing
      )

    {:noreply, %{state | params: params, total_pages: total_pages}}
  end

  @impl true
  def handle_cast({:update}, state) do
    unless state.user.last_indexed == nil do
      params = %Params.RecentTracks{
        username: Lilac.Requestable.from_user(state.user),
        limit: 500,
        from: DateTime.to_unix(state.user.last_indexed) + 1
      }

      total_pages =
        initialize_index(
          state.user,
          params,
          :updating
        )

      {:noreply, %{state | params: params, total_pages: total_pages}}
    else
      index_user(state.user)

      {:noreply, state}
    end
  end

  def handle_cast({:index_page, page_number, total_pages, params}, state) do
    unless state.paused or page_number > total_pages do
      convert_page(state.user, params, page_number)

      GenServer.cast(self(), {:index_page, page_number + 1, total_pages, params})

      {:noreply, %{state | last_indexed_page: page_number}}
    else
      {:noreply, state}
    end
  end

  @spec initialize_index(
          %Lilac.User{},
          %Params.RecentTracks{},
          Lilac.IndexingSupervisor.action(),
          integer
        ) :: integer()
  defp initialize_index(user, params, action, start_page \\ 1) do
    fetched_page = Indexing.fetch_page(user, %{params | page: start_page})

    case fetched_page do
      {:error, _error} ->
        Indexing.shutdown_subscription(params, user)
        0

      {:ok, %Responses.RecentTracks{meta: %Responses.RecentTracks.Meta{total_pages: 0}}} ->
        Indexing.shutdown_subscription(params, user)
        0

      {:ok, page} ->
        start_indexing(user, action, page, params)
    end
  end

  defp start_indexing(user, action, page, params) do
    Lilac.IndexingSupervisor.spin_up_servers(user, action)

    total_pages = page.meta.total_pages
    current_page = page.meta.page

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

    GenServer.cast(self(), {:index_page, current_page, total_pages, params})

    total_pages
  end

  @spec convert_page(Lilac.User.t(), %Params.RecentTracks{}, integer()) :: no_return()
  defp convert_page(user, params, page_number) do
    case Indexing.fetch_page(user, %{params | page: page_number}) do
      {:ok, page} ->
        IO.puts("fetching page #{page.meta.page} for user #{user.username}")

        Lilac.ConvertingServer.convert_page(
          user,
          page
        )

      {:error, error} ->
        IO.puts("An error occurred while indexing: #{inspect(error)}")
    end
  end
end
