defmodule Lilac.GuildMember do
  use Ecto.Schema

  schema("guild_members") do
    field :guild_id, :string

    belongs_to :user, Lilac.User
  end
end
