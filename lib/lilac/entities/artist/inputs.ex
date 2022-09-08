defmodule Lilac.Artist.Input do
  defstruct [:name]

  @type t() :: %__MODULE__{
          name: binary | nil
        }
end
