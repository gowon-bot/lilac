defmodule Lilac.Sync.Syncer do
  use DynamicSupervisor
  alias Lilac.Sync.Registry

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec sync(Lilac.User.t()) :: no_return()
  def sync(user) do
    full_sync_or_update(user, &Lilac.Sync.Supervisor.sync/1)
  end

  def update(user) do
    full_sync_or_update(user, &Lilac.Sync.Supervisor.sync_update/1)
  end

  defp full_sync_or_update(user, full_sync_or_update) do
    case start_child(user) do
      {:ok, _pid} ->
        full_sync_or_update.(user)

      {:error, {:already_started, _pid}} ->
        Lilac.Errors.Indexing.user_already_indexing()

      _ ->
        Lilac.Errors.Meta.unknown_server_error()
    end
  end

  @spec start_child(Lilac.User.t()) :: DynamicSupervisor.on_start_child()
  defp start_child(user) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Lilac.Sync.Supervisor,
      start: {Lilac.Sync.Supervisor, :start_link, [user]}
    })
  end

  def terminate_sync(user) do
    case GenServer.whereis(Registry.supervisor(user)) do
      nil -> nil
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
end
