defmodule Lilac.WhoFirst.Row do
  defstruct [:user, :first_scrobbled]

  @type t() :: %__MODULE__{
          user: Lilac.User.t(),
          first_scrobbled: DateTime.t()
        }
end
