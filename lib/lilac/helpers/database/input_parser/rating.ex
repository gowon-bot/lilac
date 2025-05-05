defmodule Lilac.InputParser.Rating do
  import Ecto.Query, only: [where: 3, from: 2, join: 5, select: 3]

  alias Lilac.{Artist, Album, RYM.AlbumAlbum}
  alias Lilac.InputParser

  @spec maybe_rating(Ecto.Query.t(), integer() | nil) :: Ecto.Query.t()
  def maybe_rating(query, rating) do
    case rating do
      nil -> query
      _ -> where(query, [rating: r], r.rating == ^rating)
    end
  end

  @spec maybe_album_input(Ecto.Query.t(), Album.Input.t() | nil) :: Ecto.Query.t()
  def maybe_album_input(query, album) do
    if album do
      album_subquery =
        from(l in Album, as: :album, select: l.id)
        |> join(:inner, [album: l], a in Artist, as: :artist, on: a.id == l.artist_id)
        |> InputParser.Album.maybe_album_input(album)

      album_album_subquery =
        from(l in AlbumAlbum, as: :album_album, where: l.album_id in subquery(album_subquery))
        |> select([l], l.rate_your_music_album_id)

      rym_album_subquery =
        from(rl in Lilac.RYM.Album, as: :rate_your_music_album)
        |> InputParser.Album.maybe_album_input_for_rym(album)
        |> select([l], l.id)

      where(
        query,
        [rate_your_music_album: l],
        l.id in subquery(album_album_subquery) or
          l.id in subquery(rym_album_subquery)
      )
    else
      query
    end
  end
end
