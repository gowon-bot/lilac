defmodule Lilac.Track.Input do
  defstruct [:name, :artist, :album]

  @type t() :: %__MODULE__{
          name: binary | nil,
          artist: Lilac.Artist.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil
        }
end

defmodule Lilac.Track.Filters do
  defstruct [:track, :pagination]

  @type t() :: %__MODULE__{
          track: Lilac.Track.Input.t() | nil,
          pagination: Lilac.Pagination.Input.t() | nil
        }

  @spec has_album_artist?(%__MODULE__{}) :: boolean()
  def has_album_artist?(filters) do
    Map.has_key?(Map.get(filters, :album, %{}), :artist)
  end

  @spec has_track?(%__MODULE__{}) :: boolean()
  def has_track?(filters) do
    Map.has_key?(filters, :track)
  end

  @spec has_album?(%__MODULE__{}) :: boolean()
  def has_album?(filters) do
    Map.get(filters, :track, %{}) |> Map.has_key?(:album)
  end

  @spec has_artist?(%__MODULE__{}) :: boolean()
  def has_artist?(filters) do
    Map.get(filters, :track, %{}) |> Map.has_key?(:artist)
  end
end
