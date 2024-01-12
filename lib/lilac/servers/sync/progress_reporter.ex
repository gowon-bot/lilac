defmodule Lilac.Sync.ProgressReporter do
  @moduledoc """
    Keeps track of indexing progress, and notifies its caller when all pages have been processed.
    Also pushes progress updates to the websocket
  """
  use GenServer, restart: :transient

  alias Lilac.LastFM.Responses
  alias Lilac.Sync
  alias Lilac.Sync.Registry

  # Client API

  @spec capture_progress(Lilac.User.t(), Responses.RecentTracks.t()) :: term
  def capture_progress(user, page) do
    GenServer.call(
      Registry.progress_reporter(user),
      {:capture_progress, page}
    )
  end

  @spec add_page(Lilac.User.t(), integer()) :: term
  def add_page(user, page_number) do
    GenServer.call(
      Registry.progress_reporter(user),
      {:add_page, page_number}
    )
  end

  # Server callbacks

  @spec start_link({Lilac.Sync.Supervisor.action(), Lilac.User.t()}) :: term
  def start_link({action, user}) do
    GenServer.start_link(
      __MODULE__,
      {action, user},
      name: Registry.progress_reporter(user)
    )
  end

  @impl true
  def init({action, user}) do
    {:ok, %{action: action, pages: [], page_count: 0, user: user}}
  end

  @impl true
  def handle_call({:capture_progress, page}, _from, %{
        pages: pages,
        action: action,
        page_count: page_count,
        user: user
      }) do
    pages = Enum.filter(pages, fn el -> el != page.meta.page end)

    page_count = page_count + 1

    Sync.Subscriptions.update(action, page_count, page.meta.total_pages, user.id)

    if page_count == page.meta.total_pages do
      Sync.Supervisor.self_destruct(user)
    end

    {:reply, :ok, %{pages: pages, action: action, page_count: page_count, user: user}}
  end

  @impl true
  def handle_call({:add_page, page_number}, _from, %{
        pages: pages,
        action: action,
        page_count: page_count,
        user: user
      }) do
    {:reply, :ok,
     %{pages: pages ++ [page_number], action: action, page_count: page_count, user: user}}
  end
end
