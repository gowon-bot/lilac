defmodule Lilac.RYM.Artist.Rating do
  defstruct [:avg_rating, :album_count, :artist]

  @type t() :: %__MODULE__{
          avg_rating: Float.t(),
          album_count: integer(),
          artist: Lilac.RYM.Artist.t()
        }
end
