defmodule Lilac.GraphQLHelpers.Introspection do
  @moduledoc """
  Provides methods for GraphQL query introspection
  """

  @spec has_field?(Absinthe.Resolution.t(), binary) :: boolean
  def has_field?(info, field) when is_binary(field) do
    Absinthe.Resolution.project(info) |> definition_has_field?(field)
  end

  @spec has_field?(Absinthe.Resolution.t(), [binary]) :: boolean
  def has_field?(info, fields) when is_list(fields) do
    first_definition =
      if(!is_nil(info.definition),
        do: info.definition.selections,
        else: []
      )
      |> Enum.find(fn val -> Map.get(val, :name) == Enum.at(fields, 0) end)

    definition =
      fields
      |> Enum.slice(1, length(fields) - 1)
      |> Enum.reduce(
        first_definition,
        fn field, acc ->
          if !is_nil(acc) && Map.has_key?(acc, :selections) do
            Map.get(acc, :selections) |> Enum.find(fn val -> Map.get(val, :name) == field end)
          else
            acc
          end
        end
      )

    !is_nil(definition)
  end

  @spec definition_has_field?([%{name: binary}], binary) :: boolean
  defp definition_has_field?(definition, field) do
    definition |> Enum.map(& &1.name) |> Enum.member?(field)
  end
end
