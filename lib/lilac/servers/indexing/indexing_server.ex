defmodule Lilac.IndexingServer do
  use GenServer

  alias Lilac.ConcurrencyServer
  alias Lilac.Services.Indexing

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: __MODULE__)
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
  end

  def index_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:index, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec update_user(pid | atom, Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def update_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:update, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec handle_concurrency(integer) :: {:ok, nil} | {:error, String.t()}
  defp handle_concurrency(user_id) do
    user_doing_action = ConcurrencyServer.is_doing_action?(:indexing, user_id)

    if !user_doing_action do
      ConcurrencyServer.register(:indexing, user_id)
      {:ok, nil}
    else
      Lilac.Errors.Indexing.user_already_indexing()
    end
  end

  ## Server callbacks
  @impl true
  def handle_cast({:index, user}, _state) do
    Indexing.index(user)

    {:noreply, nil}
  end

  @impl true
  def handle_cast({:update, user}, _state) do
    Indexing.update(user)

    {:noreply, nil}
  end

  @spec stop_servers(Lilac.User.t()) :: no_return
  def stop_servers(user) do
    Lilac.IndexingSupervisor.self_destruct(user)
  end
end
