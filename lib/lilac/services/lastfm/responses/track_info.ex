defmodule Lilac.LastFM.Responses.TrackInfo do
  use Lilac.LastFM.Response

  defstruct [
    :name,
    :mbid,
    :url,
    :duration,
    :listeners,
    :playcount,
    :artist,
    :album,
    :user_playcount,
    :user_loved,
    :tags
  ]

  @type t :: %__MODULE__{
          name: binary,
          mbid: binary,
          url: binary,
          duration: integer,
          listeners: integer,
          playcount: integer,
          artist: binary,
          album: binary,
          user_playcount: integer | nil,
          user_loved: boolean | nil,
          tags: [binary]
        }

  @spec from_map(map) :: %__MODULE__{}
  def from_map(map) do
    track_info = map["track"]

    %__MODULE__{
      name: track_info["name"],
      mbid: track_info["mbid"],
      url: track_info["url"],
      duration: convert_number(track_info["duration"]),
      listeners: convert_number(track_info["listeners"]),
      playcount: convert_number(track_info["playcount"]),
      user_playcount:
        if(
          Map.has_key?(track_info, "userplaycount") and !is_nil(track_info["userplaycount"]),
          do: convert_number(track_info["userplaycount"]),
          else: nil
        ),
      user_loved:
        if(
          Map.has_key?(track_info, "userloved") and !is_nil(track_info["userloved"]),
          do: convert_boolean(track_info["userloved"]),
          else: nil
        ),
      tags: convert_list(track_info["tags"]["tag"]) |> Enum.map(fn t -> t["name"] end)
    }
  end
end
