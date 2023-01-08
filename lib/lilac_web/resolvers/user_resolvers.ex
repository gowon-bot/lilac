defmodule LilacWeb.Resolvers.User do
  alias Lilac.Services.Auth
  alias Lilac.GraphQLHelpers.{Introspection, Fields}
  import Ecto.Query, only: [from: 2]

  def index(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Lilac.IndexingServer.index_user(IndexingServer, user)
  end

  def update(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Lilac.IndexingServer.update_user(IndexingServer, user)
  end

  def users(_root, %{filters: user_input}, info) do
    query = from u in Lilac.User, where: ^Keyword.new(user_input)

    users = Lilac.Repo.all(query)

    if Introspection.has_field?(info, Fields.User.is_indexing()) do
      {:ok, Lilac.Services.Users.add_is_indexing(users)}
    else
      {:ok, users}
    end
  end
end
