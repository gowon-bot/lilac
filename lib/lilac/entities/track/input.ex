defmodule Lilac.TRACK.Input do
  defstruct [:name, :artist, :album]

  @type t() :: %__MODULE__{
          name: binary | nil,
          artist: Lilac.Artist.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil
        }
end
