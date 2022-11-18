defmodule Lilac.InputParser.User do
  import Ecto.Query, only: [where: 3, dynamic: 2, dynamic: 1]

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

  @spec maybe_user_inputs(Query.t(), [Lilac.User.Input.t()]) :: Query.t()
  def maybe_user_inputs(query, inputs) do
    if is_nil(inputs) || length(inputs) == 0 do
      query
    else
      where_users =
        inputs
        |> Enum.reduce(dynamic(false), fn input, acc ->
          where_user =
            Map.keys(input)
            |> Enum.reduce(dynamic(true), fn key, acc ->
              cond do
                key == :discord_id and Map.has_key?(input, :discord_id) ->
                  discord_id = Map.get(input, :discord_id)
                  dynamic([user: u], ^acc and u.discord_id == ^discord_id)

                key == :username and Map.has_key?(input, :username) ->
                  username = Map.get(input, :username)
                  dynamic([user: u], ^acc and u.username == ^username)

                key == :id and Map.has_key?(input, :id) ->
                  id = Map.get(input, :id)
                  dynamic([user: u], ^acc and u.id == ^id)
              end
            end)

          dynamic(
            [user: u],
            ^acc or ^where_user
          )
        end)

      query |> where([user: u], ^where_users)
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
