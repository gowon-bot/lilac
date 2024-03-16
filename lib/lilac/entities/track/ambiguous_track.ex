defmodule Lilac.Track.Ambiguous do
  defstruct [:name, :artist, :tracks]

  @type t() :: %__MODULE__{
          name: binary,
          artist: Lilac.Artist.t(),
          tracks: [Lilac.Track.t()]
        }
end

defmodule Lilac.Track.Ambiguous.Page do
  defstruct [:tracks, :pagination]

  @type t() :: %__MODULE__{
          tracks: [Lilac.Track.Ambiguous.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Track.t()], %Absinthe.Resolution{}, Lilac.Track.Filters.t()) :: t()
  def generate(tracks, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Tracks.count_ambiguous(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      tracks: tracks,
      pagination: pagination
    }
  end
end
