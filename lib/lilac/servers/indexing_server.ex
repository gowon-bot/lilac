defmodule Lilac.Servers.Indexing do
  use GenServer

  # Client api

  def index_user(pid, username) do
    GenServer.cast(pid, {:index, username})
  end

  def update_user(pid, username) do
    GenServer.cast(pid, {:update, username})
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
  def handle_cast({:index, username}, _state) do
    IO.puts("Indexing #{username}")

    {:noreply, username}
  end

  @impl true
  def handle_cast({:update, username}, _state) do
    IO.puts("Indexing #{username}")

    {:noreply, username}
  end
end
