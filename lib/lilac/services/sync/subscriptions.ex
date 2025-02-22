defmodule Lilac.Sync.Subscriptions do
  alias Lilac.Sync
  alias Lilac.LastFM.API.Params

  @spec update(
          integer,
          Sync.Supervisor.action(),
          :terminated,
          binary,
          binary
        ) :: no_return
  def update(user_id, action, :terminated, err, supernova_id) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        action: action,
        stage: :terminated,
        error: err,
        supernova_id: supernova_id
      },
      sync: "#{user_id}"
    )
  end

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

  @spec terminate(Sync.Supervisor.action(), Lilac.User.t()) ::
          no_return
  def terminate(action, user) do
    # Give the client a chance to form the subscription
    Process.sleep(300)

    update(
      user.id,
      action,
      :inserting,
      %{total: 0, current: 0}
    )

    Sync.Supervisor.self_destruct(user)
  end

  @spec report_error(Params.RecentTracks.t(), Lilac.User.t(), struct) ::
          no_return
  def report_error(action, user, err) do
    supernova_id =
      case LilacWeb.ErrorReporter.handle_error(%{kind: "error", error_struct: err, user: user}) do
        %{supernova_id: id} -> id
        _ -> nil
      end

    update(
      user.id,
      action,
      :terminated,
      err |> Map.get(:message, "An unknown error occurred"),
      supernova_id
    )
  end
end
