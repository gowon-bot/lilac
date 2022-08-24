defmodule Lilac.InputParser.WhoKnows do
  import Ecto.Query, only: [from: 2]

  @spec maybe_guild_id(Ecto.Query.t(), binary) :: Ecto.Query.t()
  def maybe_guild_id(query, guild_id) do
    if !is_nil(guild_id) do
      from([ac, u] in query,
        join: gm in Lilac.GuildMember,
        on: gm.user_id == u.id and gm.guild_id == ^guild_id
      )
    else
      query
    end
  end

  @spec maybe_user_ids(Ecto.Query.t(), [binary]) :: Ecto.Query.t()
  def maybe_user_ids(query, user_ids) do
    if !is_nil(user_ids) and length(user_ids) > 0 do
      from([ac, u] in query,
        where: u.discord_id in ^user_ids
      )
    else
      query
    end
  end
end
