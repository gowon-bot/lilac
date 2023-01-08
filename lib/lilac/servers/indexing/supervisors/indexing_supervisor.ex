defmodule Lilac.IndexingSupervisor do
  use Supervisor

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(user) do
    Supervisor.start_link(__MODULE__, nil, name: Lilac.IndexerRegistry.process_name(user))
  end

  @impl true
  def init(user) do
    Supervisor.init(
      [
        {Lilac.IndexingServer, user},
        {Lilac.CountingServer, user},
        {Lilac.ConvertingServer, user},
        {Lilac.IndexingProgressServer, user}
      ],
      strategy: :one_for_one
    )
  end

  def index(_pid, _user) do
    IO.puts("indexing....")
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
        |> Enum.find(fn {id} -> id == server_name end)
        |> elem(1)
    end
  end
end
