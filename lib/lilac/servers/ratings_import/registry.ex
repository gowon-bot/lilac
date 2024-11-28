defmodule Lilac.Ratings.Import.Registry do
  @moduledoc """
  Maps user ids to Ratings.Importer child processes
  """

  def process_name(user, process) do
    {:via, Registry, {Lilac.Ratings.Import.Registry, process.(user)}}
  end

  def worker(user), do: via_tuple("ratings-import-worker-#{user.id}")

  defp via_tuple(name), do: {:via, Registry, {Lilac.Ratings.Import.Registry, name}}
end
