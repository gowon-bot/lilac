defmodule Lilac.Services.Indexing do
  import Ecto.Query, only: [from: 2]

  alias Lilac.LastFM
  alias Lilac.LastFM.API.Params
  alias Lilac.LastFM.Responses

  @spec shutdown_subscription(Lilac.LastFM.API.Params.RecentTracks.t(), Lilac.User.t()) ::
          no_return
  def shutdown_subscription(params, user) do
    # Give the client a chance to form the subscription
    Process.sleep(300)

    Lilac.IndexingProgressServer.update_subscription(
      if(is_nil(params.from), do: :indexing, else: :updating),
      0,
      0,
      user.id
    )

    Lilac.IndexingSupervisor.self_destruct(user)
  end

  @spec clear_data(%Lilac.User{}) :: no_return()
  def clear_data(user) do
    Enum.each(
      [Lilac.Scrobble, Lilac.ArtistCount, Lilac.AlbumCount, Lilac.TrackCount],
      fn elem ->
        from(e in elem, where: e.user_id == ^user.id) |> Lilac.Repo.delete_all()
      end
    )
  end

  @spec fetch_page(%Lilac.User{}, %Params.RecentTracks{}, integer) ::
          {:ok, %Responses.RecentTracks{}} | {:error, struct}
  def fetch_page(user, params, retries \\ 1) do
    recent_tracks = LastFM.recent_tracks(params)

    case recent_tracks do
      {:error, _} when retries <= 3 ->
        # Wait 300ms before trying again
        Process.sleep(300)
        fetch_page(user, params, retries + 1)

      response ->
        response
    end
  end
end
