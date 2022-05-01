# Credit to https://github.com/eproxus/parallel

defmodule Lilac.Parallel do
  def map(collection, fun, options \\ []) do
    run(collection, fun, options, [], fn item, acc -> [item | acc] end)
  end

  def each(collection, fun, options \\ []) do
    run(collection, fun, options, nil, fn _item, nil -> nil end)
  end

  def any?(collection, fun, options \\ []) do
    run(collection, fun, options, false, fn item, value -> item || value end)
  end

  def all?(collection, fun, options \\ []) do
    run(collection, fun, options, true, fn item, value -> item && value end)
  end

  # Private

  defp run(collection, fun, options, acc, update) do
    state = {pool(fun, options), [], acc, update}
    {_, busy, acc, _} = Enum.reduce(collection, state, &execute/2)
    consume(busy, acc, update)
  end

  defp execute(item, {free = [], busy, acc, update}) do
    receive do
      {ref, from, result} ->
        send(from, {ref, self(), item})
        {free, busy, update.(result, acc), update}
    end
  end

  defp execute(item, {[worker = {ref, pid} | free], busy, acc, update}) do
    send(pid, {ref, self(), item})
    {free, [worker | busy], acc, update}
  end

  defp consume(pool, acc, update) do
    Enum.reduce(pool, acc, fn {ref, pid}, acc ->
      receive do
        {^ref, ^pid, result} -> update.(result, acc)
      end
    end)
  end

  def worker(fun) do
    receive do
      {ref, sender, item} ->
        send(sender, {ref, self(), fun.(item)})
        worker(fun)

      :exit ->
        :ok
    end
  end

  defp pool(fun, options) do
    size = Keyword.get(options, :size) || :erlang.system_info(:schedulers) * 2
    spawn_worker = fn -> {make_ref(), spawn_link(fn -> worker(fun) end)} end
    Stream.repeatedly(spawn_worker) |> Enum.take(size)
  end
end

# defmodule Lilac.ConcurrentQueue do
#   use GenServer

#   # Client API

#   def test do
#     {:ok, srv} = GenServer.start_link(Lilac.ConcurrentQueue, 3)

#     Enum.each(1..4, fn i ->
#       Lilac.ConcurrentQueue.enqueue(srv, fn ->
#         Process.sleep(1000)

#         IO.puts("hello world #{i}")
#       end)
#     end)
#   end

#   def enqueue(pid, func) do
#     GenServer.call(pid, {:enqueue, func})
#   end

#   # Server callbacks

#   @impl true
#   def init(concurrency) do
#     {:ok, %{queue: [], concurrency: concurrency, processing_tasks: 0}}
#   end

#   @impl true
#   def handle_call({:enqueue, func}, __from, %{
#         queue: queue,
#         concurrency: concurrency,
#         processing_tasks: processing_tasks
#       }) do
#     queue = queue ++ [make_task(func)]

#     maybe_concurrently_process(concurrency, processing_tasks)

#     {:reply, queue, %{queue: queue, concurrency: concurrency, processing_tasks: processing_tasks}}
#   end

#   @impl true
#   def handle_cast({:dequeue, is_new_task}, %{
#         queue: queue,
#         concurrency: concurrency,
#         processing_tasks: processing_tasks
#       }) do
#     {task, queue} = List.pop_at(queue, 0, nil)
#     IO.puts("DEQUEUING #{inspect(task)}")

#     if is_nil(task) do
#       {:noreply,
#        %{
#          queue: queue,
#          concurrency: concurrency,
#          processing_tasks: if(is_new_task, do: processing_tasks, else: processing_tasks)
#        }}
#     else
#       IO.puts("Calling await from #{inspect(self())}")
#       Task.await(task)

#       {:noreply,
#        %{
#          queue: queue,
#          concurrency: concurrency,
#          processing_tasks: if(is_new_task, do: processing_tasks + 1, else: processing_tasks)
#        }}
#     end
#   end

#   @spec make_task(function) :: Task.t()
#   defp make_task(func) do
#     IO.puts("Calling async from #{inspect(self())}")

#     Task.async(fn ->
#       func.()

#       # Process the next item on the queue
#       IO.puts("Casting the next item:")
#       GenServer.cast(self(), {:dequeue, false})

#       "hello error"
#     end)
#   end

#   @spec maybe_concurrently_process(integer, integer) :: no_return()
#   defp maybe_concurrently_process(concurrency, processing_tasks) do
#     IO.puts("Maybe concurrently processing: conc: #{concurrency}, proc: #{processing_tasks}")

#     # Not processing the concurrent amount of items,
#     # process tasks until the concurrency is reached
#     if processing_tasks < concurrency do
#       Enum.each(processing_tasks..concurrency, fn _ ->
#         GenServer.cast(self(), {:dequeue, true})
#       end)
#     end
#   end
# end
