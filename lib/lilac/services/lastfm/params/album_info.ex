defmodule Lilac.LastFM.API.Params.AlbumInfo do
  defstruct [:username, :artist, :album]

  @type t :: %__MODULE__{
          username: Lilac.LastFM.API.Params.ambiguous() | nil,
          artist: binary,
          album: binary
        }
end
