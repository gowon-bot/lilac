defmodule Lilac.User do
  use Ecto.Schema

  schema("users") do
    field :discord_id, :string
    field :username, :string
    field :last_indexed, :naive_datetime_usec
    field :last_fm_session, :string, null: true
    field :privacy, Ecto.Enum, values: [private: 1, discord: 2, fm_username: 3, both: 4, unset: 5]

    has_many :artist_counts, Lilac.ArtistCount

    timestamps()
  end
end
