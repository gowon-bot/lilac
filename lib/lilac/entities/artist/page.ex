defmodule Lilac.Artist.Page do
  defstruct [:artists, :pagination]

  @type t() :: %__MODULE__{
          artists: [Lilac.Artist.t()],
          pagination: Lilac.Pagination.t()
        }
end
