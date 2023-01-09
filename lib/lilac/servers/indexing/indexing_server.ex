defmodule Lilac.IndexingServer do
  use GenServer

  alias Lilac.IndexingSupervisor
  alias Lilac.ConcurrencyServer
  alias Lilac.Services.Indexing

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: __MODULE__)
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
  end

  @spec index_user(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def index_user(user) do
    pid = IndexingSupervisor.indexing_pid(user)

    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:index})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec update_user(Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def update_user(user) do
    pid = IndexingSupervisor.indexing_pid(user)

    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:update})
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
