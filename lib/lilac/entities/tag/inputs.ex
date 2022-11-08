defmodule Lilac.Tag.Input do
  defstruct [:name]

  @type t() :: %__MODULE__{
          name: binary | nil
        }
end

defmodule Lilac.Tag.Filters do
  defstruct [:artists, :keyword, :pagination, :fetch_tags_for_missing, :inputs]

  @type t() :: %__MODULE__{
          artists: [Lilac.Artist.Input.t()] | nil,
          keyword: binary | nil,
          pagination: Lilac.Pagination.Input.t() | nil,
          fetch_tags_for_missing: boolean | nil,
          inputs: [Lilac.Tag.Input.t()] | nil
        }
end
