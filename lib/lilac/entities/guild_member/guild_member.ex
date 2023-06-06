defmodule Lilac.GuildMember do
  use Ecto.Schema

  @primary_key false
  schema("guild_members") do
    field(:guild_id, :string, primary_key: true)

    belongs_to(:user, Lilac.User, primary_key: true)
  end
end
