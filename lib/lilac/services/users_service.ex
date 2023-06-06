defmodule Lilac.Services.Users do
  alias Lilac.Services.Concurrency
  alias Lilac.User

  @spec add_is_indexing([Lilac.User.t()]) :: [Lilac.User.t()]
  def add_is_indexing(users) do
    users
    |> Enum.map(fn user ->
      %User{
        user
        | is_indexing: Concurrency.is_user_indexing?(user)
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
        last_fm_session: last_fm_session
      })
    else
      modify(user, %{last_fm_session: last_fm_session, username: username})
    end
  end

  @spec logout(User.t()) :: no_return
  def logout(user) do
    Lilac.Repo.delete(user)
  end
end
