defmodule Lilac.InputParser do
  import Ecto.Query, only: [limit: 2]

  @spec maybe_limit(Ecto.Query.t(), integer | nil) :: Ecto.Query.t()
  def maybe_limit(query, limit) do
    if !is_nil(limit) && limit > 0 do
      query |> limit(^limit)
    else
      query
    end
  end
end
