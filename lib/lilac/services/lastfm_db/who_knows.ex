defmodule Lilac.Services.WhoKnows do
  import Ecto.Query, only: [from: 2]

  alias Lilac.WhoKnows.{WhoKnowsArtistResponse, WhoKnowsArtistRank}
  alias Lilac.InputParser
  alias Lilac.InputParser.{WhoKnows}

  @spec who_knows_artist(%Lilac.Artist{}, %Lilac.WhoKnows.Input{}) :: %WhoKnowsArtistResponse{}
  def who_knows_artist(artist, settings) do
    if !artist do
      %WhoKnowsArtistResponse{artist: artist, rows: []}
    else
      rows =
        from(ac in Lilac.ArtistCount,
          join: u in Lilac.User,
          on: ac.user_id == u.id,
          where: ac.artist_id == ^artist.id,
          order_by: [desc: ac.playcount, desc: u.username],
          preload: [:user]
        )
        |> parse_who_knows_settings(settings)
        |> Lilac.Repo.all()

      %WhoKnowsArtistResponse{artist: artist, rows: rows}
    end
  end

  @spec who_knows_artist_rank(%Lilac.Artist{}, %Lilac.User{}, %Lilac.WhoKnows.Input{}) ::
          %WhoKnowsArtistRank{}
  def who_knows_artist_rank(artist, user, settings) do
    if !artist do
      %WhoKnowsArtistRank{}
    else
      rows = who_knows_artist(artist, settings).rows

      user_row_idx = Enum.find_index(rows, fn r -> r.user_id == user.id end)

      %WhoKnowsArtistRank{
        artist: artist,
        rank: user_row_idx + 1,
        playcount: Enum.at(rows, user_row_idx).playcount,
        total_listeners: length(rows),
        above: if(user_row_idx != 0, do: Enum.at(rows, user_row_idx - 1), else: nil),
        below: if(user_row_idx < length(rows) - 1, do: Enum.at(rows, user_row_idx + 1), else: nil)
      }
    end
  end

  @spec parse_who_knows_settings(Ecto.Query.t(), %Lilac.WhoKnows.Input{}) :: Ecto.Query.t()
  defp parse_who_knows_settings(query, settings) do
    query
    |> WhoKnows.maybe_guild_id(Map.get(settings, :guild_id))
    |> WhoKnows.maybe_user_ids(Map.get(settings, :user_ids))
    |> InputParser.maybe_limit(Map.get(settings, :limit))
  end
end
