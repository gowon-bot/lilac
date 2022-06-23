defmodule Lilac.Servers.Concurrency do
  @type action :: :indexing

  use GenServer, restart: :permanent

  # Client api

  @spec register(pid | atom, action(), integer) :: no_return
  def register(pid, action, user_id) do
    GenServer.call(pid, {:register, action, user_id})
  end

  @spec unregister(pid | atom, action(), integer) :: no_return
  def unregister(pid, action, user_id) do
    GenServer.call(pid, {:unregister, action, user_id})
  end

  @spec is_doing_action?(pid | atom, action(), integer) :: boolean
  def is_doing_action?(pid, action, user_id) do
    GenServer.call(pid, {:inquire, action, user_id})
  end

  # Server callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok)
  end

  @impl true
  def init(_) do
    {:ok, %{indexing: []}}
  end

  @impl true
  @spec handle_call({:register, action(), integer}, term, map) :: {:reply, :ok, map}
  def handle_call({:register, action, user_id}, _from, state) do
    state = state |> Map.put(action, Map.get(state, action) ++ [user_id])

    {:reply, :ok, state}
  end

  @impl true
  @spec handle_call({:unregister, action(), integer}, term, map) :: {:reply, :ok, map}
  def handle_call({:unregister, action, user_id}, _from, state) do
    {:reply, :ok,
     state |> Map.put(action, Map.get(state, action) |> Enum.filter(fn x -> x !== user_id end))}
  end

  @impl true
  @spec handle_call({:inquire, action(), integer}, term, map) :: {:reply, boolean, map}
  def handle_call({:inquire, action, user_id}, _from, state) do
    {:reply, !!Enum.find(Map.get(state, action), fn x -> x === user_id end), state}
  end
end
