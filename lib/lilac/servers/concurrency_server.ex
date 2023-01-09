defmodule Lilac.ConcurrencyServer do
  use GenServer

  @type action :: :indexing

  # Client api

  @spec register(action(), integer) :: no_return
  def register(action, user_id) do
    IO.puts("Registering #{user_id} as doing #{action}")
    GenServer.call(Lilac.ConcurrencyServer, {:register, action, user_id})
  end

  @spec unregister(action(), integer) :: no_return
  def unregister(action, user_id) do
    IO.puts("Unregistering #{user_id} as doing #{action}")
    GenServer.call(Lilac.ConcurrencyServer, {:unregister, action, user_id})
  end

  @spec is_doing_action?(action(), integer) :: boolean
  def is_doing_action?(action, user_id) do
    GenServer.call(Lilac.ConcurrencyServer, {:inquire, action, user_id})
  end

  # Server callbacks

  def start_link(_) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
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
