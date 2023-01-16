defmodule Lilac.IndexingSupervisor do
  use Supervisor

  alias Lilac.IndexerRegistry

  @type action :: :indexing

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    Supervisor.start_link(__MODULE__, user, name: IndexerRegistry.indexing_supervisor_name(user))
  end

  @impl true
  @spec init(Lilac.User.t()) :: no_return
  def init(user) do
    Supervisor.init(
      [
        %{
          id: IndexerRegistry.indexing_server_name(user),
          start: {Lilac.IndexingServer, :start_link, [user]}
        }
      ],
      strategy: :one_for_one
    )
  end

  def index(user) do
    Lilac.IndexingServer.index_user(user)
  end

  def update(user) do
    Lilac.IndexingServer.update_user(user)
  end

  @spec spin_up_servers(Lilac.User.t(), action()) :: no_return()
  def spin_up_servers(user, action) do
    name = IndexerRegistry.indexing_supervisor_name(user)

    if !is_nil(GenServer.whereis(name)) do
      Supervisor.start_child(name, %{
        id: IndexerRegistry.counting_server_name(user),
        start: {Lilac.CountingServer, :start_link, [user]}
      })

      Supervisor.start_child(name, %{
        id: IndexerRegistry.converting_server_name(user),
        start: {Lilac.ConvertingServer, :start_link, [user]}
      })

      Supervisor.start_child(name, %{
        id: IndexerRegistry.indexing_progress_server_name(user),
        start: {Lilac.IndexingProgressServer, :start_link, [{action, user}]}
      })
    end
  end

  def self_destruct(user) do
    Lilac.Indexer.terminate_child(user)
  end
end
