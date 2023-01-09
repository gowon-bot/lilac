defmodule Lilac.Indexer do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec index(Lilac.User.t()) :: no_return()
  def index(user) do
    index_or_update(user, &Lilac.IndexingSupervisor.index/1)
  end

  def update(user) do
    index_or_update(user, &Lilac.IndexingSupervisor.update/1)
  end

  defp index_or_update(user, index_or_update_function) do
    case start_child(user) do
      {:ok, _pid} ->
        index_or_update_function.(user)

      {:error, {:already_started, _pid}} ->
        index_or_update_function.(user)

      _ ->
        nil
    end
  end

  @spec start_child(Lilac.User.t()) :: DynamicSupervisor.on_start_child()
  defp start_child(user) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Lilac.IndexingSupervisor,
      start: {Lilac.IndexingSupervisor, :start_link, [user]}
    })
  end

  def terminate_child(user) do
    case Lilac.IndexerRegistry.get_supervisor_pid(user) do
      nil -> nil
      pid -> DynamicSupervisor.terminate_child(__MODULE__, pid)
    end
  end
end

# user = Lilac.Repo.get_by!(Lilac.User, %{id: 1})
# Lilac.Indexer.update(user)
# Lilac.Indexer.start_child(user)
