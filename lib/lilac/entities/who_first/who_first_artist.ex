defmodule Lilac.WhoFirst do
  defmodule WhoFirstArtistResponse do
    defstruct [:rows, :artist]

    @type t() :: %__MODULE__{
            rows: [Lilac.WhoFirst.Row.t()],
            artist: Lilac.Artist.t()
          }
  end

  defmodule WhoFirstArtistRank do
    defstruct [
      :artist,
      :rank,
      :first_scrobbled,
      :last_scrobbled,
      :total_listeners,
      :above,
      :below
    ]

    @type t() :: %__MODULE__{
            artist: Lilac.Artist.t(),
            rank: integer(),
            first_scrobbled: Date.t(),
            last_scrobbled: Date.t(),
            total_listeners: integer()
          }
  end
end
