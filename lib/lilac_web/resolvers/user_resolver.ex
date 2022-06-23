defmodule LilacWeb.Resolvers.User do
  alias Lilac.Services.Auth

  def index(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Helpers.Errors.doughnut_id_doesnt_match(),
      else: Lilac.Servers.Indexing.index_user(IndexingServer, user)
  end

  def update(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Helpers.Errors.doughnut_id_doesnt_match(),
      else: Lilac.Servers.Indexing.update_user(IndexingServer, user)
  end
end
