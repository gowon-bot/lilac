defmodule Lilac.TrackCount do
  use Ecto.Schema

  schema("track_counts") do
    field :playcount, :integer

    belongs_to :track, Lilac.Track
    belongs_to :user, Lilac.User
  end

  defmodule Lilac.TrackCount.Ambiguous do
    defstruct [:track, :playcount, :user]

    @type t() :: %__MODULE__{
            track: Lilac.Track.Ambiguous.t(),
            playcount: integer,
            user: Lilac.User.t()
          }
  end
end
