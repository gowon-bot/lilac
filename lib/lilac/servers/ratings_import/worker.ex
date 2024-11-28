defmodule Lilac.Ratings.Import.Worker do
  use GenServer

  alias Lilac.Ratings
  alias Lilac.Ratings.Import.{Registry, Subscriptions}

  def start_link(user) do
    GenServer.start_link(__MODULE__, user, name: Registry.worker(user))
  end

  @impl true
  def init(user) do
    {:ok, %{user: user}}
  end

  @spec start_import(Lilac.User.t(), String.t()) :: {:error, String.t()} | {:ok, nil}
  def start_import(user, csv) do
    GenServer.cast(Registry.worker(user), {:import, csv})
    {:ok, nil}
  end

  ## Server callbacks

  @impl true
  def handle_cast({:import, csv}, %{user: user}) do
    case Ratings.Parse.parse_csv(csv) do
      {:error, reason} ->
        Subscriptions.error(user.id, reason)
        {:stop, :normal, %{user: user}}

      {:ok, []} ->
        Subscriptions.error(user.id, "No ratings found!")
        {:stop, :normal, %{user: user}}

      {:ok, ratings} ->
        Subscriptions.update(user.id, :started, length(ratings))

        Ratings.clear_ratings(user)
        saved_count = save_ratings(user, ratings)

        Subscriptions.update(user.id, :finished, saved_count)
        {:stop, :normal, %{user: user}}
    end
  end

  defp save_ratings(user, ratings) do
    artist_map = fetch_artist_map(ratings)

    ratings
    |> Enum.map(&build_rating(artist_map, user, &1))
    |> Ratings.save_ratings()
    |> elem(0)
  end

  defp fetch_artist_map(ratings) do
    ratings
    |> Enum.map(&Ratings.Parse.generate_album_combinations/1)
    |> List.flatten()
    |> Enum.map(&elem(&1, 0))
    |> Enum.uniq()
    |> Enum.chunk_every(2000)
    |> Enum.map(&Lilac.Sync.Conversion.generate_artist_map/1)
    |> Enum.reduce(%{}, &Map.merge(&1, &2))
  end

  @spec build_rating(map, Lilac.User.t(), Lilac.Ratings.Parse.Types.RawRatingRow.t()) ::
          Lilac.RYM.Rating.t()
  defp build_rating(artist_map, user, rating) do
    rym_album = persist_rate_your_music_album(rating)
    Ratings.create_missing_associated_albums(rating, rym_album, artist_map)

    %{
      user_id: user.id,
      rate_your_music_album_id: rym_album.id,
      rating: rating.rating |> String.to_integer()
    }
  end

  @spec persist_rate_your_music_album(Lilac.Ratings.Parse.Types.RawRatingRow.t()) ::
          Lilac.RYM.Album.t() | nil
  defp persist_rate_your_music_album(rating) do
    case Ratings.get_album(rating.rym_id) do
      nil ->
        Ratings.create_album(rating |> sanitize_album())

      album ->
        album
    end
  end

  @spec sanitize_album(Lilac.Ratings.Parse.Types.RawRatingRow.t()) ::
          Lilac.Ratings.Parse.Types.RawRatingRow.t()
  defp sanitize_album(rating) do
    if rating.artist_name != rating.artist_name_localized do
      rating
    else
      Map.put(rating, :artist_name, "")
    end
  end
end
