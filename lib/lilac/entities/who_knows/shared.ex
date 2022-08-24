defmodule Lilac.WhoKnows.Row do
  defstruct [:user, :playcount]

  @type t() :: %__MODULE__{
          user: Lilac.User.t(),
          playcount: integer()
        }
end
