defmodule Lilac.TrackCount do
  use Ecto.Schema

  schema("track_counts") do
    field :playcount, :integer

    belongs_to :track, Lilac.Track
    belongs_to :user, Lilac.User
  end
end
