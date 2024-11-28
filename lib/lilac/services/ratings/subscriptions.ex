defmodule Lilac.Ratings.Import.Subscriptions do
  @spec update(integer, :started | :finished, integer) :: no_return
  def update(user_id, stage, count) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        stage: stage,
        count: count
      },
      ratings_import: "#{user_id}"
    )
  end

  @spec error(integer, String.t()) :: no_return
  def error(user_id, reason) do
    Absinthe.Subscription.publish(
      LilacWeb.Endpoint,
      %{
        stage: :errored,
        error: reason
      },
      ratings_import: "#{user_id}"
    )
  end
end
