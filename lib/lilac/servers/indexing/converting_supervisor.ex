defmodule Lilac.ConvertingSupervisor do
  use Supervisor, restart: :transient

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(_) do
    Supervisor.init([], strategy: :one_for_one)
  end
end
