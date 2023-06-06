defmodule LilacWeb.Resolvers.GuildMember do
  def add_to_guild(_root, %{discord_id: discord_id, guild_id: guild_id}, _info) do
    {:ok, Lilac.Services.GuildMembers.add(discord_id, guild_id)}
  end

  def remove_from_guild(_root, %{discord_id: discord_id, guild_id: guild_id}, _info) do
    {:ok, Lilac.Services.GuildMembers.remove(discord_id, guild_id)}
  end

  def sync_guild(_root, %{guild_id: guild_id, discord_ids: discord_ids}, _info) do
    {:ok, Lilac.Services.GuildMembers.sync_guild(guild_id, discord_ids)}
  end

  def clear_guild(_root, %{guild_id: guild_id}, _info) do
    {:ok, Lilac.Services.GuildMembers.clear_guild(guild_id)}
  end
end
