defmodule Lilac.Sync.Registry do
  @moduledoc """
  Maps user ids to Syncer child processes
  """

  def process_name(user, process) do
    {:via, Registry, {Lilac.Sync.Registry, process.(user)}}
  end

  def supervisor(user), do: via_tuple("sync-supervisor-#{user.id}")
  def fetcher(user), do: via_tuple("sync-fetcher-#{user.id}")
  def converter(user), do: via_tuple("sync-converter-#{user.id}")
  def progress_reporter(user), do: via_tuple("sync-progress-reporter-#{user.id}")
  def conversion_cache(user), do: via_tuple("sync-conversion-cache-#{user.id}")

  defp via_tuple(name), do: {:via, Registry, {Lilac.Sync.Registry, name}}
end
