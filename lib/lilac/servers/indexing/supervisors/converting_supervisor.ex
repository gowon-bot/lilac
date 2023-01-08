defmodule Lilac.ConvertingSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_child(user) do
    spec = %{
      id: Lilac.ConvertingServer,
      start: {Lilac.ConvertingServer, :start_link, [user]}
    }

    DynamicSupervisor.start_child(__MODULE__, spec)
  end
end
