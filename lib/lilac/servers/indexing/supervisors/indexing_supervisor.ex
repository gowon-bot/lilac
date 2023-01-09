defmodule Lilac.IndexingSupervisor do
  use Supervisor

  @supervised_servers [
    Lilac.CountingServer,
    Lilac.ConvertingServer,
    Lilac.IndexingProgressServer
  ]

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    Supervisor.start_link(__MODULE__, nil, name: Lilac.IndexerRegistry.process_name(user))
  end

  @impl true
  def init(user) do
    Supervisor.init([{Lilac.IndexingServer, user}], strategy: :one_for_one)
  end

  def index(user) do
    pid = indexing_pid(user)

    Lilac.IndexingServer.index_user(pid, user)
  end

  def update(user) do
    pid = indexing_pid(user)

    Lilac.IndexingServer.update_user(pid, user)
  end

  def spin_up_servers(user) do
    case Lilac.IndexerRegistry.get_supervisor_pid(user) do
      nil ->
        nil

      pid ->
        for server <- @supervised_servers do
          Supervisor.start_child(pid, {server, user})
        end
    end
  end

  def self_destruct(user) do
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
