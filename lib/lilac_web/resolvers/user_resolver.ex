defmodule LilacWeb.Resolvers.User do
  def index(_root, %{username: username}, _info) do
    Lilac.Servers.Indexing.index_user(IndexingServer, username)

    {:ok, nil}
  end

  def update(_root, %{username: username}, _info) do
    Lilac.Servers.Indexing.update_user(IndexingServer, username)

    {:ok, nil}
  end
end
