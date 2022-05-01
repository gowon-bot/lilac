defmodule Lilac.Servers.Indexing do
  use GenServer

  # Client api

  def index_user(pid, user) do
    GenServer.cast(pid, {:index, user})
  end

  @spec update_user(atom | pid | {atom, any} | {:via, atom, any}, any) :: :ok
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
  def handle_cast({:index, user}, _state) do
    IO.puts("Indexing #{inspect(user)}")

    {:ok, converting_pid} = GenServer.start_link(Lilac.Servers.Converting, :ok)

    Lilac.Indexing.index(converting_pid, user)

    {:noreply, nil}
  end
end
