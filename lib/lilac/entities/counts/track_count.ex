defmodule Lilac.TrackCount do
  use Ecto.Schema

  schema("track_counts") do
    field(:playcount, :integer)

    belongs_to(:track, Lilac.Track)
    belongs_to(:user, Lilac.User)
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

defmodule Lilac.TrackCount.Page do
  defstruct [:track_counts, :pagination]

  @type t() :: %__MODULE__{
          track_counts: [Lilac.TrackCount.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.TrackCount.t()], %Absinthe.Resolution{}, Lilac.TrackCount.Filters.t()) ::
          t()
  def generate(track_counts, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Tracks.count_counts(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      track_counts: track_counts,
      pagination: pagination
    }
  end
end

defmodule Lilac.TrackCount.Filters do
  defstruct [:track, :users, :pagination]

  @type t() :: %__MODULE__{
          track: Lilac.Track.Input.t() | nil,
          users: [Lilac.User.Input.t()],
          pagination: Lilac.Pagination.Input.t() | nil
        }

  @spec has_users?(%__MODULE__{}) :: boolean()
  def has_users?(filters) do
    Map.has_key?(filters, :users)
  end

  @spec has_track?(%__MODULE__{}) :: boolean()
  def has_track?(filters) do
    Map.has_key?(filters, :track)
  end

  @spec has_album?(%__MODULE__{}) :: boolean()
  def has_album?(filters) do
    Map.get(filters, :track, %{}) |> Map.has_key?(:album)
  end

  @spec has_artist?(%__MODULE__{}) :: boolean()
  def has_artist?(filters) do
    Map.get(filters, :track, %{}) |> Map.has_key?(:artist)
  end
end
