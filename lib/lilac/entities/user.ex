defmodule Lilac.User do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  schema("users") do
    field :discord_id, :string
    field :username, :string
    field :last_indexed, :utc_datetime
    field :last_fm_session, :string, null: true
    field :privacy, Ecto.Enum, values: [private: 1, discord: 2, fm_username: 3, both: 4, unset: 5]

    has_many :artist_counts, Lilac.ArtistCount
    has_many :guild_members, Lilac.GuildMember

    timestamps()
  end
end
