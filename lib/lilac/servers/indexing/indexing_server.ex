defmodule Lilac.Servers.Indexing do
  use GenServer, restart: :transient

  # Client api

  def index_user(pid, user) do
    GenServer.cast(pid, {:index, user})
  end

  def update_user(pid, user) do
    GenServer.cast(pid, {:update, user})
  end

  # Server callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(:ok) do
    {:ok, %{}}
  end

  @impl true
  @spec handle_cast({:index, %Lilac.User{}}, term) :: {:noreply, nil}
  def handle_cast({:index, user}, _state) do
    {:ok, converting_pid} =
      Supervisor.start_child(ConvertingSupervisor, {Lilac.Servers.Converting, :indexing})

    Lilac.Indexing.index(converting_pid, user)

    {:noreply, nil}
  end

  @impl true
  def handle_cast({:update, user}, _state) do
    {:ok, converting_pid} =
      Supervisor.start_child(ConvertingSupervisor, {Lilac.Servers.Converting, :updating})

    Lilac.Indexing.update(converting_pid, user)

    {:noreply, nil}
  end
end
