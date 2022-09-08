defmodule Lilac.Album.Input do
  defstruct [:name, :artist]

  @type t() :: %__MODULE__{
          name: binary | nil,
          artist: Lilac.Artist.Input.t() | nil
        }
end
