defmodule Lilac.Sync.Syncer do
  use DynamicSupervisor
  alias Lilac.Sync.Registry
  alias Lilac.Sync.ProgressReporter

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec sync(Lilac.User.t(), boolean) :: no_return()
  def sync(user, force_restart?) do
    full_sync_or_update(user, &Lilac.Sync.Supervisor.sync/1, force_restart?)
  end

  def update(user) do
    full_sync_or_update(user, &Lilac.Sync.Supervisor.update/1)
  end

  defp full_sync_or_update(user, full_sync_or_update, force_restart? \\ false) do
    case start_child(user) do
      {:ok, _pid} ->
        full_sync_or_update.(user)

      {:error, {:already_started, _pid}} when force_restart? ->
        notify_termination(user)
        terminate_sync(user)
        # Restart process only once, to prevent looping
        full_sync_or_update(user, full_sync_or_update, false)

      {:error, {:already_started, _pid}} when not force_restart? ->
        Lilac.Errors.Sync.user_already_syncing()

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
    case whereis_supervisor(user) do
      nil -> nil
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end

  def whereis_supervisor(user) do
    GenServer.whereis(Registry.supervisor(user))
  end

  def notify_termination(user) do
    ProgressReporter.capture_progress(user, :terminated, 0)
  end
end
