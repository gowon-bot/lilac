defmodule Lilac.Album.Input do
  defstruct [:name, :artist]

  @type t() :: %__MODULE__{
          name: binary | nil,
          artist: Lilac.Artist.Input.t() | nil
        }
end

defmodule Lilac.Album.Filters do
  defstruct [:album, :pagination]

  @type t() :: %__MODULE__{
          album: Lilac.Album.Input.t() | nil,
          pagination: Lilac.Pagination.Input.t() | nil
        }
end
