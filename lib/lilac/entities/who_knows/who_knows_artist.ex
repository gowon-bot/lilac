defmodule Lilac.WhoKnows do
  defmodule WhoKnowsArtistResponse do
    defstruct [:rows, :artist]

    @type t() :: %__MODULE__{
            rows: [Lilac.WhoKnows.Row.t()],
            artist: Lilac.Artist.t()
          }
  end

  defmodule WhoKnowsArtistRank do
    defstruct [:artist, :rank, :playcount, :total_listeners, :above, :below]

    @type t() :: %__MODULE__{
            artist: Lilac.Artist.t(),
            rank: integer(),
            playcount: integer(),
            total_listeners: integer(),
            above: Lilac.ArtistCount.t(),
            below: Lilac.ArtistCount.t()
          }
  end

  defmodule WhoKnowsAlbumResponse do
    defstruct [:rows, :album]

    @type t() :: %__MODULE__{
            rows: [Lilac.WhoKnows.Row.t()],
            album: Lilac.Album.t()
          }
  end

  defmodule WhoKnowsAlbumRank do
    defstruct [:album, :rank, :playcount, :total_listeners, :above, :below]

    @type t() :: %__MODULE__{
            album: Lilac.Album.t(),
            rank: integer(),
            playcount: integer(),
            total_listeners: integer(),
            above: Lilac.AlbumCount.t(),
            below: Lilac.AlbumCount.t()
          }
  end
end
