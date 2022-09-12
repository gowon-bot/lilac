defmodule Lilac.LastFM.API.Params.RecentTracks do
  @type t :: %__MODULE__{
          username: Lilac.LastFM.API.Params.ambiguous(),
          from: integer | nil,
          to: integer | nil,
          limit: integer,
          page: integer
        }

  defstruct [:username, :from, :to, limit: 100, page: 1]
end
