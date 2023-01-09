defmodule Lilac.IndexingServer do
  use GenServer
  alias Lilac.ConcurrencyServer
  alias Lilac.Services.Indexing

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: __MODULE__)
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
  end

  def index_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:index, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec update_user(pid | atom, Lilac.User.t()) :: {:error, String.t()} | {:ok, nil}
  def update_user(pid, user) do
    case handle_concurrency(user.id) do
      {:ok, _} ->
        GenServer.cast(pid, {:update, user})
        {:ok, nil}

      error ->
        error
    end
  end

  @spec handle_concurrency(integer) :: {:ok, nil} | {:error, String.t()}
  defp handle_concurrency(user_id) do
    user_doing_action = ConcurrencyServer.is_doing_action?(:indexing, user_id)

    if !user_doing_action do
      ConcurrencyServer.register(:indexing, user_id)
      {:ok, nil}
    else
      Lilac.Errors.Indexing.user_already_indexing()
    end
  end

  ## Server callbacks

  @impl true
  # @spec handle_cast({:index, Lilac.User.t()}, term) :: {:noreply, nil}
  def handle_cast({:index, user}, _state) do
    Indexing.index(user)

    {:noreply, nil}
  end

  # @impl true
  # @spec handle_cast({:update, Lilac.User.t()}, term) :: {:noreply, nil}
  # def handle_cast({:update, user}, _state) do
  #   pids = start_servers(:updating, user)

  #   Lilac.Indexing.update(pids, user)

  #   {:noreply, nil}
  # end

  @spec stop_servers(Lilac.User.t()) :: no_return
  def stop_servers(user) do
    IO.puts("TERMINATE ME")
    # Supervisor.terminate_child(ConvertingSupervisor, converting_child_id(user.id))
    # Supervisor.terminate_child(ConvertingSupervisor, indexing_progress_child_id(user.id))
  end

  # @spec start_servers(:indexing | :updating, Lilac.User.t()) :: %{
  #         converting: pid,
  #         indexing_progress: pid
  #       }
  # defp start_servers(action, user) do
  #   converting_pid =
  #     case Supervisor.restart_child(ConvertingSupervisor, converting_child_id(user.id)) do
  #       {:ok, pid} ->
  #         pid

  #       {:error, :not_found} ->
  #         {:ok, converting_pid} =
  #           Supervisor.start_child(
  #             ConvertingSupervisor,
  #             create_converting_child_spec(user)
  #           )

  #         converting_pid

  #       {:error, :running} ->
  #         Supervisor.terminate_child(ConvertingSupervisor, converting_child_id(user.id))

  #         start_servers(action, user)
  #     end

  #   indexing_progress_pid =
  #     case Supervisor.restart_child(ConvertingSupervisor, indexing_progress_child_id(user.id)) do
  #       {:ok, pid} ->
  #         pid

  #       {:error, :not_found} ->
  #         {:ok, indexing_progress_pid} =
  #           Supervisor.start_child(
  #             ConvertingSupervisor,
  #             create_indexing_progress_child_spec(action, user)
  #           )

  #         indexing_progress_pid

  #       {:error, :running} ->
  #         Supervisor.terminate_child(ConvertingSupervisor, indexing_progress_child_id(user.id))

  #         start_servers(action, user)
  #     end

  #   %{converting: converting_pid, indexing_progress: indexing_progress_pid}
  # end

  # @spec create_converting_child_spec(Lilac.User.t()) ::
  #         :supervisor.child_spec()
  # defp create_converting_child_spec(user) do
  #   Supervisor.child_spec({Lilac.Servers.Converting, %{}}, id: converting_child_id(user.id))
  # end

  # @spec create_indexing_progress_child_spec(:indexing | :updating, Lilac.User.t()) ::
  #         :supervisor.child_spec()
  # defp create_indexing_progress_child_spec(action, user) do
  #   Supervisor.child_spec({Lilac.Servers.IndexingProgress, action},
  #     id: indexing_progress_child_id(user.id)
  #   )
  # end

  # @spec converting_child_id(integer) :: binary
  # defp converting_child_id(user_id) do
  #   child_id(user_id, :converting)
  # end

  # @spec indexing_progress_child_id(integer) :: binary
  # defp indexing_progress_child_id(user_id) do
  #   child_id(user_id, :indexing_progress)
  # end

  # @spec child_id(integer, :converting | :indexing_progress) :: binary
  # defp child_id(user_id, action) do
  #   case action do
  #     :converting -> "#{user_id}-converting"
  #     :indexing_progress -> "#{user_id}-indexing-progress"
  #   end
  # end
end
