defmodule Lilac.Track.Ambiguous do
  defstruct [:name, :artist, :tracks]

  @type t() :: %__MODULE__{
          name: binary,
          artist: Lilac.Artist.t(),
          tracks: [Lilac.Track.t()]
        }
end
