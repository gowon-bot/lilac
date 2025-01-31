defmodule Lilac.Services.Users do
  alias Lilac.Services.Concurrency
  alias Lilac.User

  import Ecto.Query, only: [from: 2, where: 3]

  @spec add_is_user_syncing([User.t()]) :: [User.t()]
  def add_is_user_syncing(users) do
    users
    |> Enum.map(fn user ->
      %User{
        user
        | is_syncing: Concurrency.is_user_syncing?(user)
      }
    end)
  end

  @spec modify(User.t(), User.Modifications.t()) :: User.t()
  def modify(user, modifications) do
    Ecto.Changeset.change(user, modifications) |> Lilac.Repo.update!()
  end

  @spec login(User.t() | nil, binary, binary | nil, binary) :: User.t()
  def login(user, username, last_fm_session, discord_id) do
    if is_nil(user) do
      Lilac.Repo.insert!(%User{
        discord_id: discord_id,
        username: username,
        last_fm_session: last_fm_session,
        privacy: :unset
      })
    else
      modify(user, %{last_fm_session: last_fm_session, username: username})
    end
  end

  @spec logout(User.t()) :: no_return
  def logout(user) do
    Lilac.Repo.delete(user)
  end

  @spec get_users_by_discord_ids([binary]) :: [User.t()]
  def get_users_by_discord_ids(ids) do
    from(u in User, as: :user)
    |> where([user: u], u.discord_id in ^ids)
    |> Lilac.Repo.all()
  end
end
