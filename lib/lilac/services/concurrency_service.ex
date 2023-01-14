defmodule Lilac.Services.Concurrency do
  alias Lilac.IndexerRegistry

  def is_user_indexing?(user) do
    !is_nil(GenServer.whereis(IndexerRegistry.indexing_supervisor_name(user)))
  end
end
