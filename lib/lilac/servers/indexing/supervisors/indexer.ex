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
    case start_child(user) do
      {:ok, pid} ->
        Lilac.IndexingSupervisor.index(pid, user)

      _ ->
        nil
    end
  end

  @spec start_child(Lilac.User.t()) :: DynamicSupervisor.on_start_child()
  def start_child(user) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Lilac.IndexingSupervisor,
      start: {Lilac.IndexingSupervisor, :start_link, [user]}
    })
  end
end

# Lilac.Indexer.index(%Lilac.User{id: 1})
# Lilac.Indexer.start_child(%Lilac.User{id: 1})
