defmodule Lilac.LastFM.Responses.RecentTracks do
  use Lilac.LastFM.Response

  @type t :: %__MODULE__{
          tracks: [__MODULE__.RecentTrack],
          meta: __MODULE__.Meta
        }
  defstruct [:tracks, :meta]

  defmodule RecentTrack do
    @type t :: %__MODULE__{
            artist: binary,
            artist_mbid: binary,
            is_now_playing: boolean,
            mbid: binary,
            album: binary,
            album_mbid: binary,
            # TODO: add image collections
            # images: binary,
            streamable: boolean,
            url: binary,
            name: binary,
            scrobbled_at: DateTime.t()
          }

    defstruct [
      :artist,
      :artist_mbid,
      :is_now_playing,
      :mbid,
      :album,
      :album_mbid,
      :images,
      :streamable,
      :url,
      :name,
      :scrobbled_at
    ]
  end

  defmodule Meta do
    @type t :: %__MODULE__{
            page: integer,
            total: integer,
            per_page: integer,
            total_pages: integer,
            username: binary
          }
    defstruct [:page, :total, :per_page, :total_pages, :username]
  end

  @spec from_map(map) :: %__MODULE__{}
  def from_map(map) do
    attr = map["recenttracks"]["@attr"]

    %__MODULE__{
      meta: %__MODULE__.Meta{
        page: convert_number(attr["page"]),
        per_page: convert_number(attr["perPage"]),
        total: convert_number(attr["total"]),
        total_pages: convert_number(attr["totalPages"]),
        username: attr["user"]
      },
      tracks:
        Enum.map(convert_list(map["recenttracks"]["track"]), fn track ->
          is_now_playing =
            if(Map.has_key?(track, "@attr"),
              do: convert_boolean(track["@attr"]["nowplaying"]),
              else: false
            )

          %__MODULE__.RecentTrack{
            artist: track["artist"]["#text"],
            artist_mbid: track["artist"]["mbid"],
            is_now_playing: is_now_playing,
            mbid: track["mbid"],
            album: track["album"]["#text"],
            album_mbid: track["album"]["mbid"],
            # images:
            streamable: convert_boolean(track["streamable"]),
            url: track["url"],
            name: track["name"],
            scrobbled_at:
              if(is_now_playing,
                do: nil,
                else: convert_number(track["date"]["uts"]) |> DateTime.from_unix!(:second)
              )
          }
        end)
    }
  end
end
