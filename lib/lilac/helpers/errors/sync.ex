defmodule Lilac.Errors.Sync do
  def user_already_syncing do
    {:error, "User is already syncing!"}
  end
end
