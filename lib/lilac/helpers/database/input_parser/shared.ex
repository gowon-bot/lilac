defmodule Lilac.InputParser do
  import Ecto.Query, only: [limit: 2, offset: 2]

  alias Ecto.Query

  @spec maybe_limit(Query.t(), integer | nil) :: Query.t()
  def maybe_limit(query, limit) do
    if !is_nil(limit) && limit > 0 do
      query |> limit(^limit)
    else
      query
    end
  end

  @spec maybe_page_input(Query.t(), Lilac.Pagination.Input.t()) :: Query.t()
  def maybe_page_input(query, page_input) do
    if !is_nil(page_input) do
      query
      |> limit(^page_input.per_page)
      |> offset(^page_input.per_page * (^page_input.page - 1))
    else
      query
    end
  end

  def value_not_nil(map, key) do
    !is_nil(Map.get(map, key))
  end

  @spec escape_like(String.t()) :: String.t()
  def escape_like(string) do
    string
    |> String.replace("%", "\\%")
    |> String.replace("_", "\\_")
  end
end
