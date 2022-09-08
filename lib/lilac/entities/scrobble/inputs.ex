defmodule Lilac.Scrobble.Filters do
  defstruct [:artist, :album, :track, :user, :pagination]

  @type t() :: %__MODULE__{
          artist: Lilac.Artist.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil,
          track: Lilac.Track.Input.t() | nil,
          user: Lilac.User.Input.t() | nil,
          pagination: Lilac.Pagination.Input.t() | nil
        }
end
