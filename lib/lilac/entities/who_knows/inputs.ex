defmodule Lilac.WhoKnows.Input do
  defstruct [:guild_id, :limit, :user_ids]

  @type t() :: %__MODULE__{
          guild_id: String.t() | nil,
          limit: integer() | nil,
          user_ids: [String.t()] | nil
        }
end
