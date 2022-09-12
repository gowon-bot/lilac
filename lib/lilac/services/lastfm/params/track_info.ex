defmodule Lilac.LastFM.API.Params.TrackInfo do
  defstruct [:username, :artist, :track]

  @type t :: %__MODULE__{
          username: Lilac.LastFM.API.Params.ambiguous() | nil,
          artist: binary,
          track: binary
        }
end
