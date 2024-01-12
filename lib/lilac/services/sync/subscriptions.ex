defmodule Lilac.Sync.Subscriptions do
  alias Lilac.Sync
  alias Lilac.LastFM.API.Params

  @spec update(Sync.Supervisor.action(), integer, integer, integer) :: no_return
  def update(action, page, total_pages, user_id) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        page: page,
        total_pages: total_pages,
        action: action
      },
      index: "#{user_id}"
    )
  end

  @spec terminate(Params.RecentTracks.t(), Lilac.User.t()) ::
          no_return
  def terminate(params, user) do
    # Give the client a chance to form the subscription
    Process.sleep(300)

    update(
      if(is_nil(params.from), do: :indexing, else: :updating),
      0,
      0,
      user.id
    )

    Sync.Supervisor.self_destruct(user)
  end
end
