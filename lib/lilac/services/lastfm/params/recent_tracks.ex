defmodule Lilac.LastFM.API.Params.RecentTracks do
  @type t :: %__MODULE__{
          username: Lilac.LastFM.API.Params.ambiguous(),
          from: number | nil,
          to: number | nil,
          limit: number,
          page: number
        }

  defstruct [:username, :from, :to, limit: 100, page: 1]
end
