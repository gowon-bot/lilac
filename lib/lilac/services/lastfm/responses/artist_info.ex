defmodule Lilac.LastFM.Responses.ArtistInfo do
  use Lilac.LastFM.Response

  defstruct [
    :name,
    :url,
    :streamable,
    :on_tour,
    :listeners,
    :playcount,
    :user_playcount,
    :similar_artists,
    :tags
  ]

  @type t :: %__MODULE__{
          name: binary,
          url: binary,
          streamable: boolean,
          on_tour: boolean,
          listeners: integer,
          playcount: integer,
          user_playcount: integer | nil,
          similar_artists: [
            %{
              name: binary,
              url: binary
              # Todo
              # images: binary
            }
          ],
          tags: [binary]
        }

  @spec from_map(map) :: %__MODULE__{}
  def from_map(map) do
    artist_info = map["artist"]

    %__MODULE__{
      name: artist_info["name"],
      url: artist_info["url"],
      streamable: convert_boolean(artist_info["streamable"]),
      on_tour: convert_boolean(artist_info["ontour"]),
      listeners: convert_number(artist_info["stats"]["listeners"]),
      playcount: convert_number(artist_info["stats"]["playcount"]),
      user_playcount:
        if(
          Map.has_key?(artist_info["stats"], "userplaycount") and
            !is_nil(artist_info["stats"]["userplaycount"]),
          do: convert_number(artist_info["stats"]["userplaycount"]),
          else: nil
        ),
      similar_artists:
        convert_list(artist_info["similar"]["artist"])
        |> Enum.map(fn sa ->
          %{
            name: sa["name"],
            url: sa["url"]
          }
        end),
      tags: convert_list(artist_info["tags"]["tag"]) |> Enum.map(fn t -> t["name"] end)
    }
  end
end
