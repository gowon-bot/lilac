defmodule Lilac.Database.InsertHelpers do
  @spec add_timestamps_to_many([map]) :: [map]
  def add_timestamps_to_many(map_list) do
    Enum.map(map_list, fn element ->
      now = Timex.now() |> Timex.to_naive_datetime() |> NaiveDateTime.truncate(:second)

      element |> Map.put(:inserted_at, now) |> Map.put(:updated_at, now)
    end)
  end
end
