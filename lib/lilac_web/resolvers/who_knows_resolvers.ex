defmodule LilacWeb.Resolvers.WhoKnows do
  def who_knows_artist(_root, args, _info) do
    case Lilac.LastFM.get_artist(args.artist.name) do
      {:ok, artist} ->
        {:ok, Lilac.Services.WhoKnows.who_knows_artist(artist, Map.get(args, :settings, %{}))}

      error ->
        error
    end
  end

  def who_knows_artist_rank(_root, args, _info) do
    case Lilac.LastFM.get_artist(args.artist.name) do
      {:ok, artist} ->
        {:ok,
         Lilac.Services.WhoKnows.who_knows_artist_rank(
           artist,
           Lilac.Repo.get_by(Lilac.User, args.user),
           Map.get(args, :settings, %{})
         )}

      error ->
        error
    end
  end

  def who_knows_album(_root, args, _info) do
    case Lilac.LastFM.get_album(args.album.artist.name, args.album.name) do
      {:ok, album} ->
        {:ok, Lilac.Services.WhoKnows.who_knows_album(album, Map.get(args, :settings, %{}))}

      error ->
        error
    end
  end

  def who_knows_album_rank(_root, args, _info) do
    case Lilac.LastFM.get_album(args.album.artist.name, args.album.name) do
      {:ok, album} ->
        {:ok,
         Lilac.Services.WhoKnows.who_knows_album_rank(
           album,
           Lilac.Repo.get_by(Lilac.User, args.user),
           Map.get(args, :settings, %{})
         )}

      error ->
        error
    end
  end
end
