defmodule Lilac.User.Input do
  defstruct [:id, :username, :discord_id]

  @type t() :: %__MODULE__{
          id: integer | nil,
          username: binary | nil,
          discord_id: binary | nil
        }
end
