defmodule Lilac.LastFM.Responses.AlbumInfo do
  use Lilac.LastFM.Response

  defstruct [
    :name,
    :artist,
    :url,
    :listeners,
    :playcount,
    :user_playcount,
    :tracks,
    :tags
    # :images
  ]

  @type t :: %__MODULE__{
          name: binary,
          artist: binary,
          listeners: integer,
          playcount: integer,
          user_playcount: integer | nil,
          tracks: [
            %{
              name: binary,
              url: binary,
              duration: integer,
              number: integer | nil,
              artist: binary
              # Todo
              # images: binary
            }
          ],
          tags: [binary]
        }

  @spec from_map(map) :: %__MODULE__{}
  def from_map(map) do
    album_info = map["album"]

    %__MODULE__{
      name: album_info["name"],
      url: album_info["url"],
      listeners: convert_number(album_info["listeners"]),
      playcount: convert_number(album_info["playcount"]),
      user_playcount:
        if(
          Map.has_key?(album_info, "userplaycount") and !is_nil(album_info["userplaycount"]),
          do: convert_number(album_info["userplaycount"]),
          else: nil
        ),
      tracks:
        convert_list(album_info["tracks"]["track"])
        |> Enum.map(fn t ->
          %{
            name: t["name"],
            url: t["url"],
            duration: convert_number(t["duration"]),
            number:
              if(Map.has_key?(t, ["@attr"]) and Map.has_key?(t["@attr"], "rank"),
                do: convert_number(t["@attr"]["rank"]),
                else: 0
              ),
            artist: t["artist"]
          }
        end),
      tags: convert_list(album_info["tags"]["tag"]) |> Enum.map(fn t -> t["name"] end)
    }
  end
end
