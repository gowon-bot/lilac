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
end
