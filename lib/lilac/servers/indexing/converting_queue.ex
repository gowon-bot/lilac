defmodule Lilac.ConvertingQueue do
  use GenServer

  alias Lilac.IndexingServer
  alias Lilac.IndexerRegistry

  defp suspend_threshold, do: 10
  defp resume_threshold, do: 3

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: IndexerRegistry.converting_queue_name(user))
  end

  def increment_queue(user) do
    GenServer.call(IndexerRegistry.converting_queue_name(user), {:increment_queue})
  end

  def decrement_queue(user) do
    GenServer.call(IndexerRegistry.converting_queue_name(user), {:decrement_queue})
  end

  @impl true
  @spec init(Lilac.User.t()) :: {:ok, map}
  def init(user) do
    {:ok, %{queue_length: 0, user: user, is_suspended: false}}
  end

  @impl true
  def handle_call({:increment_queue}, _from, %{
        queue_length: queue_length,
        user: user,
        is_suspended: is_suspended
      }) do
    {:reply, :ok,
     %{
       queue_length: queue_length + 1,
       user: user,
       is_suspended: maybe_suspend_or_resume_indexing(user, queue_length + 1, is_suspended)
     }}
  end

  @impl true
  def handle_call({:decrement_queue}, _from, %{
        queue_length: queue_length,
        user: user,
        is_suspended: is_suspended
      }) do
    {:reply, :ok,
     %{
       queue_length: queue_length - 1,
       user: user,
       is_suspended: maybe_suspend_or_resume_indexing(user, queue_length + 1, is_suspended)
     }}
  end

  defp maybe_suspend_or_resume_indexing(user, queue_length, is_suspended) do
    cond do
      !is_suspended && queue_length >= suspend_threshold() ->
        IndexingServer.pause_page_fetching(user)
        true

      is_suspended && queue_length <= resume_threshold() ->
        IndexingServer.resume_page_fetching(user)
        false

      true ->
        is_suspended
    end
  end
end
