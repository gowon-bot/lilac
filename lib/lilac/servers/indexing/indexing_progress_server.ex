defmodule Lilac.Servers.IndexingProgress do
  @moduledoc """
    Keeps track of indexing progress, and notifies its caller when all pages have been processed.
    Also pushes progress updates to the websocket
  """
  use GenServer, restart: :transient

  alias Lilac.Servers.Concurrency

  # Client API

  @spec capture_progress(atom | pid | {atom, any} | {:via, atom, any}, any, any) :: any
  def capture_progress(pid, user, page) do
    GenServer.call(pid, {:capture_progress, user, page})
  end

  def add_page(pid, page_number) do
    GenServer.call(pid, {:add_page, page_number})
  end

  @spec shutdown(%Lilac.User{}) :: no_return()
  def shutdown(user) do
    Concurrency.unregister(ConcurrencyServer, :indexing, user.id)
    Lilac.Servers.Indexing.stop_servers(user)
  end

  # Server callbacks

  @spec start_link(:indexing | :updating) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(action) do
    GenServer.start_link(__MODULE__, action)
  end

  @impl true
  def init(action) do
    {:ok, %{action: action, pages: [], page_count: 0}}
  end

  @impl true
  def handle_call({:capture_progress, user, page}, _from, %{
        pages: pages,
        action: action,
        page_count: page_count
      }) do
    pages = Enum.filter(pages, fn el -> el != page.meta.page end)

    page_count = page_count + 1

    update_subscription(action, page_count, page.meta.total_pages, user.id)

    if page_count == page.meta.total_pages do
      shutdown(user)

      {:reply, :ok, %{pages: pages, action: action, page_count: page_count}}
    else
      {:reply, :ok, %{pages: pages, action: action, page_count: page_count}}
    end
  end

  @impl true
  def handle_call({:add_page, page_number}, _from, %{
        pages: pages,
        action: action,
        page_count: page_count
      }) do
    {:reply, :ok, %{pages: pages ++ [page_number], action: action, page_count: page_count}}
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
