defmodule LilacWeb.Resolvers.User do
  import Ecto.Query, only: [from: 2]

  alias Lilac.Services.Auth
  alias Lilac.GraphQLHelpers.{Introspection, Fields}
  alias Lilac.Sync.Syncer

  def sync(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Syncer.sync(user)
  end

  def update(_root, %{user: user_input}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: Syncer.update(user)
  end

  def users(_root, %{filters: user_input}, info) do
    query = from(u in Lilac.User, where: ^Keyword.new(user_input))

    users = Lilac.Repo.all(query)

    if Introspection.has_field?(info, Fields.User.is_syncing()) do
      {:ok, Lilac.Services.Users.add_is_user_syncing(users)}
    else
      {:ok, users}
    end
  end

  def modify(_root, %{user: user_input, modifications: modifications}, %{context: context}) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: {:ok, Lilac.Services.Users.modify(user, modifications)}
  end

  def login(_root, %{username: username, last_fm_session: session, discord_id: discord_id}, %{
        context: context
      }) do
    user = Lilac.Repo.get_by(Lilac.User, %{discord_id: discord_id})

    if !is_nil(user) and !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: {:ok, Lilac.Services.Users.login(user, username, session, discord_id)}
  end

  def logout(_root, %{user: user_input}, %{
        context: context
      }) do
    user = Lilac.Repo.get_by!(Lilac.User, user_input)

    if !Auth.is_authorized?(context, user),
      do: Lilac.Errors.Meta.doughnut_id_doesnt_match(),
      else: {:ok, Lilac.Services.Users.logout(user)}
  end
end
