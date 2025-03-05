defmodule Lilac.Helpers.Map do
  @spec ensure_map(map | nil) :: map
  def ensure_map(map) when is_map(map), do: map
  def ensure_map(nil), do: %{}
end
