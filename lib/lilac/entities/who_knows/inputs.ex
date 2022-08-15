defmodule Lilac.Entities.WhoKnows.Input do
  defstruct guild_id: binary(), limit: integer(), user_ids: [binary()]
end
