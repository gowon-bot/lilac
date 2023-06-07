defmodule Lilac.Services.GuildMembers do
  import Ecto.Query, only: [from: 2, join: 5, where: 3]

  alias Lilac.GuildMember
  alias Lilac.User

  @spec add(binary, binary) :: GuildMember.t()
  def add(discord_id, guild_id) do
    user = Lilac.Repo.get_by!(User, %{discord_id: discord_id})

    %Lilac.GuildMember{guild_id: guild_id, user: user} |> Lilac.Repo.insert!(returning: true)
  end

  @spec remove(binary, binary) :: integer
  def remove(discord_id, guild_id) do
    from(gm in GuildMember,
      as: :guild_member
    )
    |> join(:inner, [guild_member: gm], u in assoc(gm, :user), as: :user)
    |> where(
      [guild_member: gm, user: u],
      gm.guild_id == ^guild_id and u.discord_id == ^discord_id
    )
    |> Lilac.Repo.delete_all()
    |> elem(0)
  end

  @spec sync_guild(binary, [binary]) :: integer
  def sync_guild(guild_id, discord_ids) do
    clear_guild(guild_id)

    guild_members =
      discord_ids
      |> Lilac.Services.Users.get_users_by_discord_ids()
      |> Enum.map(fn u -> %{guild_id: guild_id, user_id: u.id} end)

    Lilac.Repo.insert_all(GuildMember, guild_members) |> elem(0)
  end

  @spec clear_guild(binary) :: integer
  def clear_guild(guild_id) do
    from(gm in GuildMember,
      as: :guild_member
    )
    |> where(
      [guild_member: gm],
      gm.guild_id == ^guild_id
    )
    |> Lilac.Repo.delete_all()
    |> elem(0)
  end
end
