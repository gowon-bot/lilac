defmodule Lilac.Scrobble.Filters do
  defstruct [:artist, :album, :track, :user, :pagination]

  @type t() :: %__MODULE__{
          artist: Lilac.Artist.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil,
          track: Lilac.Track.Input.t() | nil,
          user: Lilac.User.Input.t() | nil,
          pagination: Lilac.Pagination.Input.t() | nil
        }

  @spec has_album?(%__MODULE__{}) :: boolean()
  def has_album?(filters) do
    Map.has_key?(filters, :album)
  end

  @spec has_track?(%__MODULE__{}) :: boolean()
  def has_track?(filters) do
    Map.has_key?(filters, :track)
  end

  @spec has_artist?(%__MODULE__{}) :: boolean()
  def has_artist?(filters) do
    Map.has_key?(filters, :artist)
  end

  @spec has_user?(%__MODULE__{}) :: boolean()
  def has_user?(filters) do
    Map.has_key?(filters, :user)
  end
end
