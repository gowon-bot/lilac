defmodule Lilac.Services.LastFMAPI.Types do
  defmodule RecentTracksParams do
    defstruct [:username, :from, :to, limit: 100, page: 1]
  end
end
