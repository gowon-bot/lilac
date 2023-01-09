defmodule Lilac.IndexingProgressServer do
  @moduledoc """
    Keeps track of indexing progress, and notifies its caller when all pages have been processed.
    Also pushes progress updates to the websocket
  """
  use GenServer, restart: :transient

  alias Lilac.LastFM.Responses

  # Client API

  @spec capture_progress(Lilac.User.t(), Responses.RecentTracks.t()) :: term
  def capture_progress(user, page) do
    pid = Lilac.IndexingSupervisor.indexing_progress_pid(user)

    GenServer.call(pid, {:capture_progress, page})
  end

  @spec add_page(Lilac.User.t(), integer()) :: term
  def add_page(user, page_number) do
    pid = Lilac.IndexingSupervisor.indexing_progress_pid(user)

    GenServer.call(pid, {:add_page, page_number})
  end

  # Server callbacks

  @spec start_link({:indexing | :updating, Lilac.User.t()}) :: term
  def start_link({action, user}) do
    GenServer.start_link(__MODULE__, {action, user})
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

    update_subscription(action, page_count, page.meta.total_pages, user.id)

    if page_count == page.meta.total_pages do
      Lilac.IndexingSupervisor.self_destruct(user)
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

  @spec update_subscription(:indexing | :updating, integer, integer, integer) :: no_return
  def update_subscription(action, page, total_pages, user_id) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        page: page,
        total_pages: total_pages,
        action: action
      },
      index: "#{user_id}"
    )
  end
end
