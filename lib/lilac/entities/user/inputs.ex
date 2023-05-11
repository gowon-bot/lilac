defmodule Lilac.User.Input do
  defstruct [:id, :username, :discord_id]

  @type t() :: %__MODULE__{
          id: integer | nil,
          username: binary | nil,
          discord_id: binary | nil
        }
end

defmodule Lilac.User.Modifications do
  defstruct [:username, :discord_id, :privacy, :last_fm_session]

  @type t() :: %__MODULE__{
          username: binary | nil,
          discord_id: binary | nil,
          privacy: integer | nil,
          last_fm_session: binary | nil
        }
end
