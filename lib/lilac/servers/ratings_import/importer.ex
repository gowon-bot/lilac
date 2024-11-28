defmodule Lilac.Ratings.Import.Importer do
  use DynamicSupervisor
  alias Lilac.Ratings.Import.Registry

  def start_link(_) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec import(Lilac.User.t(), String.t()) :: no_return()
  def import(user, csv) do
    case start_child(user) do
      {:ok, _pid} ->
        start_import(user, csv)

      {:error, {:already_started, _pid}} ->
        Lilac.Errors.Ratings.user_already_importing()

      _ ->
        Lilac.Errors.Meta.unknown_server_error()
    end
  end

  @spec start_child(Lilac.User.t()) :: DynamicSupervisor.on_start_child()
  defp start_child(user) do
    DynamicSupervisor.start_child(__MODULE__, %{
      id: Registry.worker(user),
      start: {Lilac.Ratings.Import.Worker, :start_link, [user]},
      restart: :temporary
    })
  end

  @spec start_import(Lilac.User.t(), String.t()) :: no_return()
  def start_import(user, csv) do
    Lilac.Ratings.Import.Worker.start_import(user, csv)
  end
end
