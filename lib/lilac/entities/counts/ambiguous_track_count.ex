defmodule Lilac.TrackCount.Ambiguous do
  defstruct [:track, :playcount, :user]

  @type t() :: %__MODULE__{
          track: Lilac.Track.Ambiguous.t(),
          playcount: integer,
          user: Lilac.User.t()
        }
end

defmodule Lilac.TrackCount.Ambiguous.Page do
  defstruct [:track_counts, :pagination]

  @type t() :: %__MODULE__{
          track_counts: [Lilac.TrackCount.Ambiguous.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate(
          [Lilac.TrackCount.Ambiguous.t()],
          %Absinthe.Resolution{},
          Lilac.TrackCount.Filters.t()
        ) ::
          t()
  def generate(track_counts, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Tracks.count_ambiguous_counts(filters),
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
