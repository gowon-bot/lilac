defmodule Lilac.Services.WhoFirst do
  alias Lilac.WhoFirst.WhoFirstArtistResponse

  import Ecto.Query,
    only: [from: 2, subquery: 1, where: 3, preload: 2, select_merge: 3]

  alias Lilac.Services.WhoKnows
  alias Lilac.WhoFirst.WhoFirstArtistRank
  alias Lilac.Helpers

  @spec who_first_artist(Lilac.Artist.t(), Lilac.WhoKnows.Input.t()) :: WhoFirstArtistResponse.t()
  def who_first_artist(artist, settings) do
    if !artist do
      %WhoFirstArtistResponse{artist: artist, rows: []}
    else
      rows =
        if(Map.get(settings, :reverse),
          do: last_scrobbled_query(),
          else: first_scrobbled_query()
        )
        |> where([ac], ac.artist_id == ^artist.id and not is_nil(ac.first_scrobbled))
        |> preload([:user])
        |> WhoKnows.parse_who_knows_settings(settings)
        |> Lilac.Repo.all()

      %WhoFirstArtistResponse{artist: artist, rows: rows}
    end
  end

  @spec who_first_artist_rank(Lilac.Artist.t(), Lilac.User.t(), Lilac.WhoKnows.Input.t()) ::
          WhoFirstArtistRank.t()
  def who_first_artist_rank(artist, user, settings) do
    if !artist do
      %WhoFirstArtistRank{artist: artist}
    else
      query =
        if(Map.get(settings, :reverse),
          do: last_scrobbled_rank_query(artist),
          else: first_scrobbled_rank_query(artist)
        )
        |> select_merge([ac, u], %{rank: row_number() |> over(:p)})
        |> WhoKnows.parse_who_knows_settings(settings |> Map.delete(:limit))

      user_entry =
        from(ac in subquery(query),
          where: ac.user_id == ^user.id
        )
        |> Lilac.Repo.one()
        |> Helpers.Map.ensure_map()

      count =
        from(ac in Lilac.ArtistCount,
          join: u in Lilac.User,
          on: ac.user_id == u.id,
          where: ac.artist_id == ^artist.id and not is_nil(ac.first_scrobbled),
          select: count(u.id)
        )
        |> WhoKnows.parse_who_knows_settings(settings |> Map.delete(:limit))
        |> Lilac.Repo.one()

      %WhoFirstArtistRank{
        artist: artist,
        rank: Map.get(user_entry, :rank, 0),
        first_scrobbled: Map.get(user_entry, :first_scrobbled),
        last_scrobbled: Map.get(user_entry, :last_scrobbled),
        total_listeners: count
      }
    end
  end

  @spec first_scrobbled_query() :: Ecto.Query.t()
  defp first_scrobbled_query() do
    from(ac in Lilac.ArtistCount,
      join: u in Lilac.User,
      on: ac.user_id == u.id,
      order_by: [asc: ac.first_scrobbled, asc: u.username]
    )
  end

  @spec last_scrobbled_query() :: Ecto.Query.t()
  defp last_scrobbled_query() do
    from(ac in Lilac.ArtistCount,
      join: u in Lilac.User,
      on: ac.user_id == u.id,
      order_by: [desc: ac.last_scrobbled, asc: u.username]
    )
  end

  @spec first_scrobbled_rank_query(Lilac.Artist.t()) :: Ecto.Query.t()
  defp first_scrobbled_rank_query(artist) do
    from(ac in Lilac.ArtistCount,
      join: u in Lilac.User,
      on: ac.user_id == u.id,
      where: ac.artist_id == ^artist.id and not is_nil(ac.first_scrobbled),
      windows: [
        p: [partition_by: ac.artist_id, order_by: [asc: ac.first_scrobbled]]
      ]
    )
  end

  @spec last_scrobbled_rank_query(Lilac.Artist.t()) :: Ecto.Query.t()
  defp last_scrobbled_rank_query(artist) do
    from(ac in Lilac.ArtistCount,
      join: u in Lilac.User,
      on: ac.user_id == u.id,
      where: ac.artist_id == ^artist.id and not is_nil(ac.last_scrobbled),
      windows: [
        p: [partition_by: ac.artist_id, order_by: [desc: ac.last_scrobbled]]
      ]
    )
  end
end
