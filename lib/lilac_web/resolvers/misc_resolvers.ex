defmodule LilacWeb.Resolvers.Misc do
  def ping(_root, _args, _info) do
    {:ok, :pong}
  end
end
