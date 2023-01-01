defmodule Lilac.GraphQLHelpers do
  @spec has_field(Absinthe.Resolution.t(), binary) :: boolean
  def has_field(info, field) do
    IO.puts(inspect(Absinthe.Resolution.project(info) |> Enum.map(& &1.name)))

    Absinthe.Resolution.project(info) |> Enum.map(& &1.name) |> Enum.member?(field)
  end
end
