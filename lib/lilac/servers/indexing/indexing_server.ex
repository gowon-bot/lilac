defmodule Lilac.Servers.Indexing do
  use GenServer, restart: :transient

  # Client api

  def index_user(pid, user) do
    GenServer.cast(pid, {:index, user})
  end

  def update_user(pid, user) do
    :ok = GenServer.cast(pid, {:update, user})
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
    pids = start_servers(:indexing, user)

    Lilac.Indexing.index(pids, user)

    {:noreply, nil}
  end

  @impl true
  @spec handle_cast({:update, %Lilac.User{}}, term) :: {:noreply, nil}
  def handle_cast({:update, user}, _state) do
    pids = start_servers(:updating, user)

    Lilac.Indexing.update(pids, user)

    {:noreply, nil}
  end

  @spec stop_servers(%Lilac.User{}) :: no_return
  def stop_servers(user) do
    Supervisor.terminate_child(ConvertingSupervisor, "#{user.id}-converting")
    Supervisor.terminate_child(ConvertingSupervisor, "#{user.id}-indexing-progress")

    # idk how to really do this yet lol
    # Supervisor.delete_child(ConvertingSupervisor, "#{user.id}-converting")
    # Supervisor.delete_child(ConvertingSupervisor, "#{user.id}-indexing-progress")
  end

  @spec start_servers(:indexing | :updating, %Lilac.User{}) :: %{
          converting: pid,
          indexing_progress: pid
        }
  defp start_servers(action, user) do
    if Enum.any?(Supervisor.which_children(ConvertingSupervisor)) do
      {:ok, converting_pid} =
        Supervisor.restart_child(ConvertingSupervisor, "#{user.id}-converting")

      {:ok, indexing_progress_pid} =
        Supervisor.restart_child(ConvertingSupervisor, "#{user.id}-indexing-progress")

      %{
        converting: converting_pid,
        indexing_progress: indexing_progress_pid
      }
    else
      {:ok, converting_pid} =
        Supervisor.start_child(
          ConvertingSupervisor,
          create_converting_child_spec(action, user)
        )

      {:ok, indexing_progress_pid} =
        Supervisor.start_child(
          ConvertingSupervisor,
          create_indexing_progress_child_spec(action, user)
        )

      %{
        converting: converting_pid,
        indexing_progress: indexing_progress_pid
      }
    end
  end

  @spec create_converting_child_spec(:indexing | :updating, %Lilac.User{}) ::
          :supervisor.child_spec()
  defp create_converting_child_spec(action, user) do
    Supervisor.child_spec({Lilac.Servers.Converting, action}, id: "#{user.id}-converting")
  end

  @spec create_indexing_progress_child_spec(:indexing | :updating, %Lilac.User{}) ::
          :supervisor.child_spec()
  defp create_indexing_progress_child_spec(action, user) do
    Supervisor.child_spec({Lilac.Servers.IndexingProgress, action},
      id: "#{user.id}-indexing-progress"
    )
  end
end
