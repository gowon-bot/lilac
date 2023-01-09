defmodule Lilac.IndexingSupervisor do
  alias Lilac.ConcurrencyServer
  use Supervisor

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    Supervisor.start_link(__MODULE__, user, name: Lilac.IndexerRegistry.process_name(user))
  end

  @impl true
  @spec init(Lilac.User.t()) :: no_return
  def init(user) do
    Supervisor.init([{Lilac.IndexingServer, user}], strategy: :one_for_one)
  end

  def index(user) do
    Lilac.IndexingServer.index_user(user)
  end

  def update(user) do
    Lilac.IndexingServer.update_user(user)
  end

  @spec spin_up_servers(Lilac.User.t(), ConcurrencyServer.action()) :: no_return()
  def spin_up_servers(user, action) do
    case Lilac.IndexerRegistry.get_supervisor_pid(user) do
      nil ->
        nil

      pid ->
        Supervisor.start_child(pid, {Lilac.CountingServer, user})
        Supervisor.start_child(pid, {Lilac.ConvertingServer, user})
        Supervisor.start_child(pid, {Lilac.IndexingProgressServer, {action, user}})
    end
  end

  def self_destruct(user) do
    Lilac.ConcurrencyServer.unregister(:indexing, user.id)
    Lilac.Indexer.terminate_child(user)
  end

  def indexing_pid(user) do
    get_pid(user, Lilac.IndexingServer)
  end

  def indexing_progress_pid(user) do
    get_pid(user, Lilac.IndexingProgressServer)
  end

  def converting_pid(user) do
    get_pid(user, Lilac.ConvertingServer)
  end

  def couting_pid(user) do
    get_pid(user, Lilac.CountingServer)
  end

  defp get_pid(user, server_name) do
    case Lilac.IndexerRegistry.get_supervisor_pid(user) do
      nil ->
        nil

      pid ->
        Supervisor.which_children(pid)
        |> Enum.find(fn child -> child |> elem(0) == server_name end)
        |> elem(1)
    end
  end
end
