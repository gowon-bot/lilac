defmodule Lilac.Artist.Input do
  defstruct [:name]

  @type t() :: %__MODULE__{
          name: binary | nil
        }
end

defmodule Lilac.Artist.Filters do
  defstruct [:inputs, :tags, :pagination, :fetch_tags_for_missing]

  @type t() :: %__MODULE__{
          inputs: [Lilac.Artist.Input.t()] | nil,
          tags: [Lilac.Tag.Input.t()] | nil,
          pagination: Lilac.Pagination.Input.t() | nil,
          fetch_tags_for_missing: boolean | nil
        }
end
