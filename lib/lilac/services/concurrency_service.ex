defmodule Lilac.Services.Concurrency do
  alias Lilac.Sync

  def is_user_syncing?(user) do
    !is_nil(GenServer.whereis(Sync.Registry.supervisor(user)))
  end
end
