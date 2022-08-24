defmodule Lilac.LastFM.API.Params.ArtistInfo do
  @type t :: %__MODULE__{
          username: Lilac.LastFM.API.Params.ambiguous() | nil,
          artist: binary
        }

  defstruct [:username, :artist]
end
