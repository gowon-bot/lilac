defmodule Lilac.Services.Ratings do
  import Ecto.Query, only: [from: 2, order_by: 3, select: 3, group_by: 3]

  alias Lilac.RYM
  alias Lilac.{Joiner, InputParser}

  @spec list(RYM.Rating.Filters.t()) :: [RYM.Rating.t()]
  def list(filters) do
    from(r in RYM.Rating, as: :rating)
    |> Joiner.Rating.join_rym_album(true)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_rating_filters(filters)
    |> order_by([rating: r, rate_your_music_album: l],
      desc: r.rating,
      desc: l.artist_name,
      desc: l.title
    )
    |> Lilac.Repo.all()
  end

  @spec count(RYM.Rating.Filters.t()) :: integer
  def count(filters) do
    from(r in RYM.Rating, as: :rating, select: count())
    |> Joiner.Rating.join_rym_album(false)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_rating_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec list_artist_ratings(RYM.Rating.Artist.Filters.t()) :: [RYM.Artist.Rating.t()]
  def list_artist_ratings(filters) do
    from(r in RYM.Rating, as: :rating)
    |> Joiner.Rating.join_rym_album(false)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_artist_rating_filters(filters)
    |> group_by(
      [rating: r, rate_your_music_album: l],
      [l.artist_native_name, l.artist_name]
    )
    |> select(
      [rating: r, rate_your_music_album: l],
      %{
        average_rating: type(avg(r.rating), :float),
        album_count: count(l.rate_your_music_id),
        user_count: count(r.user_id),
        artist: %{
          artist_name: l.artist_name,
          artist_native_name: l.artist_native_name
        }
      }
    )
    |> order_by([rating: r, rate_your_music_album: l],
      desc: type(avg(r.rating), :float),
      desc: count(l.rate_your_music_id)
    )
    |> Lilac.Repo.all()
  end

  @spec count_artist_ratings(RYM.Rating.Artist.Filters.t()) :: integer
  def count_artist_ratings(filters) do
    from(r in RYM.Rating, as: :rating, select: count())
    |> Joiner.Rating.join_rym_album(false)
    |> Joiner.Rating.maybe_join_user(filters)
    |> parse_artist_rating_filters(filters |> Map.put(:pagination, nil))
    |> Lilac.Repo.one()
  end

  @spec get_artist(String.t()) :: RYM.Artist.t()
  def get_artist(keywords) do
    from(l in RYM.Album,
      where:
        ilike(l.artist_name, ^keywords) or
          ilike(l.artist_native_name, ^keywords),
      limit: 1
    )
    |> Lilac.Repo.one()
  end

  @spec parse_rating_filters(Ecto.Query.t(), Rating.Filters.t()) :: Ecto.Query.t()
  defp parse_rating_filters(query, filters) do
    query
    |> InputParser.maybe_page_input(Map.get(filters, :pagination))
    |> InputParser.User.maybe_user_input(Map.get(filters, :user))
    |> InputParser.Rating.maybe_album_input(Map.get(filters, :album))
    |> InputParser.Rating.maybe_rating(Map.get(filters, :rating))
  end

  @spec parse_artist_rating_filters(Ecto.Query.t(), Rating.Artist.Filters.t()) :: Ecto.Query.t()
  defp parse_artist_rating_filters(query, filters) do
    album_input = %{
      artist: Map.get(filters, :artist)
    }

    query
    |> InputParser.User.maybe_user_inputs(filters |> Map.get(:users))
    |> InputParser.WhoKnows.maybe_guild_id(filters |> Map.get(:guild_id))
    |> InputParser.maybe_page_input(filters |> Map.get(:pagination))
    |> InputParser.Rating.maybe_album_input(album_input)
  end
end
