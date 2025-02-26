defmodule LilacWeb.Resolvers.Misc do
  def ping(_root, _args, _info) do
    {:ok, :pong}
  end

  def version(_root, _args, _info) do
    commit_hash = Application.get_env(:lilac, :commit_hash)
    {:ok, commit_hash}
  end
end
