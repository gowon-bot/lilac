defmodule Lilac.Tag.Page do
  defstruct [:tags, :pagination]

  @type t() :: %__MODULE__{
          tags: [Lilac.Tag.t()],
          pagination: Lilac.Pagination.t()
        }
end
