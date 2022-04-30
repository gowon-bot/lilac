defmodule Lilac.Servers.Indexing do
  use GenServer

  # Client api

  def index_user(pid, ambiguous_requestable) do
    GenServer.cast(pid, {:index, ambiguous_requestable})
  end

  def update_user(pid, ambiguous_requestable) do
    GenServer.cast(pid, {:update, ambiguous_requestable})
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
  def handle_cast({:index, ambiguous_requestable}, _state) do
    IO.puts("Indexing #{Lilac.Requestable.from_ambiguous(ambiguous_requestable).username}")

    {:noreply, ambiguous_requestable}
  end

  @impl true
  def handle_cast({:update, ambiguous_requestable}, _state) do
    IO.puts("Updating #{Lilac.Requestable.from_ambiguous(ambiguous_requestable).username}")

    {:noreply, ambiguous_requestable}
  end
end
