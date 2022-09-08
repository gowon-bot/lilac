defmodule Lilac.Scrobble.Page do
  defstruct [:scrobbles, :pagination]

  @type t() :: %__MODULE__{
          scrobbles: [Lilac.Scrobble.t()],
          pagination: Lilac.Pagination.t()
        }
end
