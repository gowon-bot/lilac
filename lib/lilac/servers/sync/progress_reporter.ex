defmodule Lilac.Sync.ProgressReporter do
  @moduledoc """
    Keeps track of sync progress, and pushes updates to the websocket
    Happens in two stages:
      - fetching: when the scrobbles are being fetched and converted
      - inserting: when the generated artist, album, and track counts are being persisted to the database
  """
  use GenServer, restart: :transient

  alias Lilac.Sync
  alias Lilac.Sync.Registry

  @type stage :: :fetching | :inserting | :terminated
  @type stage_progress :: %{total: integer, current: integer}

  # Client API

  @spec capture_progress(Lilac.User.t(), stage, integer) :: no_return()
  def capture_progress(user, stage, count) do
    GenServer.call(
      Registry.progress_reporter(user),
      {stage, count}
    )
  end

  @spec set_total(Lilac.User.t(), stage, integer) :: no_return()
  def set_total(user, stage, total) do
    GenServer.call(
      Registry.progress_reporter(user),
      {:set_total, stage, total}
    )
  end

  # Server callbacks

  @spec start_link({Lilac.Sync.Supervisor.action(), Lilac.User.t()}) :: term
  def start_link({action, user}) do
    GenServer.start_link(
      __MODULE__,
      {action, user},
      name: Registry.progress_reporter(user)
    )
  end

  @impl true
  def init({action, user}) do
    {:ok,
     %{
       action: action,
       user: user,
       counts: %{total: 0, current: 0},
       scrobbles: %{total: 0, current: 0}
     }}
  end

  @impl true
  def handle_call({:fetching, scrobble_count}, _from, %{
        action: action,
        user: user,
        scrobbles: %{total: total_scrobbles, current: current_scrobbles},
        counts: counts
      }) do
    current_scrobbles = current_scrobbles + scrobble_count

    Sync.Subscriptions.update(user.id, action, :fetching, %{
      total: total_scrobbles,
      current: current_scrobbles
    })

    {:reply, :ok,
     %{
       action: action,
       user: user,
       counts: counts,
       scrobbles: %{total: total_scrobbles, current: current_scrobbles}
     }}
  end

  @impl true
  def handle_call({:inserting, chunk_size}, _from, %{
        action: action,
        user: user,
        scrobbles: scrobbles,
        counts: %{total: total_entities, current: current_entities}
      }) do
    current_entities = current_entities + chunk_size

    Sync.Subscriptions.update(user.id, action, :inserting, %{
      total: total_entities,
      current: current_entities
    })

    {:reply, :ok,
     %{
       action: action,
       user: user,
       scrobbles: scrobbles,
       counts: %{total: total_entities, current: current_entities}
     }}
  end

  @impl true
  def handle_call({:terminated, _}, _from, %{user: user, action: action}) do
    Sync.Subscriptions.update(user.id, action, :terminated, %{
      total: 0,
      current: 0
    })

    {:reply, :ok,
     %{
       action: action,
       user: user,
       scrobbles: 0,
       counts: %{total: 0, current: 0}
     }}
  end

  @impl true
  def handle_call({:set_total, :fetching, total_scrobbles}, _from, state) do
    {:reply, :ok, %{state | scrobbles: %{current: 0, total: total_scrobbles}}}
  end

  @impl true
  def handle_call({:set_total, :inserting, total_entities}, _from, state) do
    {:reply, :ok, %{state | counts: %{current: 0, total: total_entities}}}
  end
end
