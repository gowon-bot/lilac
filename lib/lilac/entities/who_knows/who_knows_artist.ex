defmodule Lilac.WhoKnows do
  defmodule WhoKnowsArtistResponse do
    defstruct [:rows, :artist]

    @type t() :: %__MODULE__{
            rows: [Lilac.WhoKnows.Row.t()],
            artist: Lilac.Artist.t()
          }
  end

  defmodule WhoKnowsArtistRank do
    defstruct [:artist, :rank, :playcount, :total_listeners, :above, :below]

    @type t() :: %__MODULE__{
            artist: Lilac.Artist.t(),
            rank: integer(),
            playcount: integer(),
            total_listeners: integer(),
            above: Lilac.ArtistCount.t(),
            below: Lilac.ArtistCount.t()
          }
  end
end
