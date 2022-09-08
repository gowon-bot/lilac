defmodule Lilac.Pagination.Input do
  defstruct [:page, :per_page]

  @type t() :: %__MODULE__{
          page: integer,
          per_page: integer
        }
end
