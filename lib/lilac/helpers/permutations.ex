defmodule Lilac.Permutations do
  def permutations(list, n) when n > 0 do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {elem, index} ->
      remaining = List.delete_at(list, index)
      for perm <- permutations(remaining, n - 1), do: [elem | perm]
    end)
  end

  def permutations(_, 0), do: [[]]
end
