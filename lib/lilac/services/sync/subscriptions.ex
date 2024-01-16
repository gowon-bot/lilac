defmodule Lilac.Sync.Subscriptions do
  alias Lilac.Sync
  alias Lilac.LastFM.API.Params

  @spec update(
          integer,
          Sync.Supervisor.action(),
          Sync.ProgressReporter.stage(),
          Sync.ProgressReporter.stage_progress()
        ) :: no_return
  def update(user_id, action, stage, stage_progress) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        action: action,
        stage: stage,
        current: stage_progress.current,
        total: stage_progress.total
      },
      sync: "#{user_id}"
    )
  end

  @spec terminate(Params.RecentTracks.t(), Lilac.User.t()) ::
          no_return
  def terminate(params, user) do
    # Give the client a chance to form the subscription
    Process.sleep(300)

    update(
      user.id,
      if(is_nil(params.from), do: :sync, else: :update),
      :inserting,
      %{total: 0, current: 0}
    )

    Sync.Supervisor.self_destruct(user)
  end
end
