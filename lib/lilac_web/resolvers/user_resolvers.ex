defmodule LilacWeb.Resolvers.User do
  alias Lilac.Services.Auth
  import Ecto.Query, only: [from: 2]

  def index(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Lilac.Servers.Indexing.index_user(IndexingServer, user)
  end

  def update(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Lilac.Servers.Indexing.update_user(IndexingServer, user)
  end

  def users(_root, %{filters: user_input}, _context) do
    query = from u in Lilac.User, where: ^Keyword.new(user_input)

    {:ok, Lilac.Repo.all(query)}
  end
end
