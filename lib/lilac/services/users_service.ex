defmodule Lilac.Services.Users do
  alias Lilac.Servers.Concurrency
  alias Lilac.User

  @spec add_is_indexing([Lilac.User.t()]) :: [Lilac.User.t()]
  def add_is_indexing(users) do
    users
    |> Enum.map(fn user ->
      %User{
        user
        | is_indexing: Concurrency.is_doing_action?(ConcurrencyServer, :indexing, user.id)
      }
    end)
  end
end
