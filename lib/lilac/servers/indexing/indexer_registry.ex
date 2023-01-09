defmodule Lilac.IndexerRegistry do
  @moduledoc """
  Maps user ids to IndexingSupervisor processes
  """

  def process_name(user) do
    {:via, Registry, {Lilac.IndexerRegistry, registry_key(user)}}
  end

  def get_supervisor_pid(user) do
    Registry.lookup(Lilac.IndexerRegistry, registry_key(user))
    |> Enum.at(0)
    |> case do
      {pid, nil} -> pid
      nil -> nil
    end
  end

  defp registry_key(user) do
    "#{user.id}"
  end
end
