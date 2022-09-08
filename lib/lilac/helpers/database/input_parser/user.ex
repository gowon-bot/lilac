defmodule Lilac.InputParser.User do
  import Ecto.Query, only: [where: 3]

  alias Lilac.InputParser
  alias Ecto.Query

  @spec maybe_user_input(Query.t(), Lilac.User.Input.t()) :: Query.t()
  def maybe_user_input(query, input) do
    if is_nil(input) do
      query
    else
      query
      |> maybe_user_id(input)
      |> maybe_username(input)
      |> maybe_discord_id(input)
    end
  end

  @spec maybe_user_id(Query.t(), Lilac.User.Input.t()) :: Query.t()
  defp maybe_user_id(query, input) do
    if InputParser.value_not_nil(input, :id) do
      query |> where([user: u], u.id == ^input.id)
    else
      query
    end
  end

  @spec maybe_username(Query.t(), Lilac.User.Input.t()) :: Query.t()
  defp maybe_username(query, input) do
    if InputParser.value_not_nil(input, :username) do
      query |> where([user: u], u.username == ^input.username)
    else
      query
    end
  end

  @spec maybe_discord_id(Query.t(), Lilac.User.Input.t()) :: Query.t()
  defp maybe_discord_id(query, input) do
    if InputParser.value_not_nil(input, :discord_id) do
      query |> where([user: u], u.discord_id == ^input.discord_id)
    else
      query
    end
  end
end
