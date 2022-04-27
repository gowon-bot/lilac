defmodule Lilac.CountingMap do
  @moduledoc """
  CountingMap holds methods to interact with maps
  specialized for converting counting entities

  All keys should be ids
  """

  @type counting_maps :: %{artists: map, albums: map, tracks: map}

  @spec increment(map, integer) :: map
  def increment(map, id) do
    Map.update(map, id, 1, fn val -> val + 1 end)
  end
end
