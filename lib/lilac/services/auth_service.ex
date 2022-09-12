defmodule Lilac.Services.Auth do
  @spec is_authorized?(map, %Lilac.User{}) :: boolean
  def is_authorized?(context, user) do
    is_nil(Map.get(context, :doughnut_id)) || user.discord_id === context.doughnut_id
  end
end
