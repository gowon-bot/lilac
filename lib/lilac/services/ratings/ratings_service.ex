defmodule Lilac.Ratings do
  import Ecto.Query, only: [from: 2, order_by: 3, select: 3, group_by: 3]

  alias Lilac.RYM
  alias Lilac.{Joiner, InputParser}
  alias Lilac.Sync.Conversion
  alias Lilac.NestedMap

  @spec clear_ratings(Lilac.User.t()) :: :ok
  def clear_ratings(user) do
    from(r in RYM.Rating, where: r.user_id == ^user.id)
    |> Lilac.Repo.delete_all()
  end

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

  @spec get_album(binary) :: RYM.Album.t()
  def get_album(rym_id) do
    from(l in RYM.Album,
      where: l.rate_your_music_id == ^rym_id,
      limit: 1
    )
    |> Lilac.Repo.one()
  end

  @spec create_album(Lilac.Ratings.Parse.Types.RawRatingRow.t()) :: RYM.Album.t()
  def create_album(rating) do
    album = %RYM.Album{
      rate_your_music_id: rating.rym_id,
      artist_name: rating.artist_name_localized,
      artist_native_name: rating.artist_name,
      title: rating.title,
      release_year: rating.release_year
    }

    Lilac.Repo.insert!(album)
  end

  @spec create_missing_associated_albums(RYM.Rating.t(), RYM.Album.t(), map) ::
          [RYM.AlbumAlbum.t()]
  def create_missing_associated_albums(rating, rym_album, artist_map) do
    combinations = Lilac.Ratings.Parse.generate_album_combinations(rating)
    album_map = combinations |> Conversion.generate_album_map(artist_map, nil)

    combinations
    |> keep_real_albums(artist_map, album_map)
    |> reject_existing_associated_albums(rym_album, artist_map, album_map)
    |> create_associated_albums(rym_album, artist_map, album_map)
  end

  @spec save_ratings([map()]) :: [RYM.Rating.t()]
  def save_ratings(ratings) do
    Lilac.Repo.insert_all(RYM.Rating, ratings, returning: true)
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

  @spec keep_real_albums([Conversion.Cache.raw_album()], map, map) ::
          [Conversion.Cache.raw_album()]
  defp keep_real_albums(albums, artist_map, album_map) do
    Enum.filter(albums, fn album ->
      NestedMap.has?(album_map, [NestedMap.get(artist_map, album |> elem(0)), album |> elem(1)])
    end)
  end

  @spec reject_existing_associated_albums(
          [Conversion.Cache.raw_album()],
          RYM.Album.t(),
          map,
          map
        ) :: [Conversion.Cache.raw_album()]
  defp reject_existing_associated_albums(albums, rym_album, artist_map, album_map) do
    album_ids = album_map |> Map.values() |> Enum.map(&Map.values/1) |> List.flatten()

    existing_associated_albums =
      from(l in RYM.AlbumAlbum,
        where: l.rate_your_music_album_id == ^rym_album.id and l.album_id in ^album_ids,
        select: l.album_id
      )
      |> Lilac.Repo.all()

    Enum.reject(albums, fn album ->
      Enum.member?(
        existing_associated_albums,
        NestedMap.get(album_map, [NestedMap.get(artist_map, album |> elem(0)), album |> elem(1)])
      )
    end)
  end

  @spec create_associated_albums([Conversion.Cache.raw_album()], RYM.Album.t(), map, map) ::
          [RYM.AlbumAlbum.t()]
  defp create_associated_albums(albums, rym_album, artist_map, album_map) do
    albums_to_insert =
      Enum.map(albums, fn album ->
        %{
          rate_your_music_album_id: rym_album.id,
          album_id:
            NestedMap.get(album_map, [
              NestedMap.get(artist_map, album |> elem(0)),
              album |> elem(1)
            ])
        }
      end)

    if length(albums_to_insert) > 0 do
      Lilac.Repo.insert_all(RYM.AlbumAlbum, albums_to_insert)
    else
      []
    end
  end
end
