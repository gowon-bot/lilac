defmodule Lilac.IndexerRegistry do
  def process_name(user) do
    {:via, Registry, {Lilac.IndexerRegistry, registry_key(user)}}
  end

  def get_supervisor_pid(user) do
    Registry.lookup(Lilac.IndexerRegistry, registry_key(user))
  end

  defp registry_key(user) do
    "#{user.id}"
  end
end
