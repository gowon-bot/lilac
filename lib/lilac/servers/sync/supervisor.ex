defmodule Lilac.Sync.Supervisor do
  use Supervisor

  alias Lilac.Sync
  alias Lilac.Sync.{Registry, Fetcher, Syncer}

  @type action :: :sync | :update

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    Supervisor.start_link(__MODULE__, user, name: Registry.supervisor(user))
  end

  @impl true
  @spec init(Lilac.User.t()) :: no_return
  def init(user) do
    Supervisor.init(
      [
        %{
          id: Registry.fetcher(user),
          start: {Sync.Fetcher, :start_link, [user]}
        }
      ],
      strategy: :one_for_one
    )
  end

  def sync(user) do
    Fetcher.start_sync(user)
  end

  def update(user) do
    Fetcher.start_update(user)
  end

  # This function spins up all the necessary servers for syncing,
  # this is only called if there are actually scrobbles to sync
  @spec spin_up_servers(Lilac.User.t(), action()) :: no_return()
  def spin_up_servers(user, action) do
    name = Registry.supervisor(user)

    if !is_nil(GenServer.whereis(name)) do
      Supervisor.start_child(name, %{
        id: Registry.converter(user),
        start: {Sync.Converter, :start_link, [user]}
      })

      Supervisor.start_child(name, %{
        id: Registry.progress_reporter(user),
        start: {Sync.ProgressReporter, :start_link, [{action, user}]}
      })

      Supervisor.start_child(name, %{
        id: Registry.conversion_cache(user),
        start: {Sync.Conversion.Cache, :start_link, [user]}
      })
    end
  end

  def self_destruct(user) do
    Syncer.terminate_sync(user)
  end
end
