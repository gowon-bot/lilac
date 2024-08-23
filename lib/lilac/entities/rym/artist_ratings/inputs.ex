defmodule Lilac.RYM.Artist.Rating.Filters do
  defstruct [:artist, :users, :guildID, :pagination]

  @type t() :: %__MODULE__{
          artist: Lilac.RYM.Artist.Input.t() | nil,
          users: [Lilac.User.Input.t()] | nil,
          guildID: String.t() | nil,
          pagination: Lilac.Pagination.Input.t() | nil
        }
end
