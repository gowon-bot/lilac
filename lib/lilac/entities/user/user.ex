defmodule Lilac.User do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  schema("users") do
    field(:discord_id, :string)
    field(:username, :string)
    field(:last_synced, :utc_datetime)
    field(:last_fm_session, :string)
    field(:has_premium, :boolean)

    field(:privacy, Ecto.Enum, values: [private: 1, discord: 2, fmusername: 3, both: 4, unset: 5])

    has_many(:artist_counts, Lilac.ArtistCount)
    has_many(:album_counts, Lilac.AlbumCount)
    has_many(:track_counts, Lilac.TrackCount)
    has_many(:guild_members, Lilac.GuildMember)
    has_many(:ratings, Lilac.RYM.Rating)

    timestamps()

    # Not persisted
    field(:is_syncing, :boolean, virtual: true)
  end
end
