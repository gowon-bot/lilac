defmodule Lilac.IndexingServer do
  use GenServer

  alias Lilac.IndexerRegistry
  alias Lilac.Services.Indexing

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: IndexerRegistry.indexing_server_name(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
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

  ## Server callbacks
  @impl true
  def handle_cast({:index}, %{user: user}) do
    Indexing.index(user)

    {:noreply, %{user: user}}
  end

  @impl true
  def handle_cast({:update}, %{user: user}) do
    Indexing.update(user)

    {:noreply, %{user: user}}
  end
end
