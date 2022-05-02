defmodule LilacWeb.Resolvers.User do
  def index(_root, %{user: user_input}, _info) do
    user = Lilac.Repo.get!(Lilac.User, user_input.id)

    Lilac.Servers.Indexing.index_user(IndexingServer, user)

    {:ok, nil}
  end

  def update(_root, %{user: user_input}, _info) do
    user = Lilac.Repo.get!(Lilac.User, user_input.id)

    Lilac.Servers.Indexing.update_user(IndexingServer, user)

    {:ok, nil}
  end
end
