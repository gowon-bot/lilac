defmodule Lilac.RYM.Artist do
  defstruct [:artistName, :artistNativeName]

  @type t() :: %__MODULE__{
          artistName: String.t(),
          artistNativeName: String.t() | nil
        }
end
