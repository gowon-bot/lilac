defmodule Lilac.Track.Page do
  defstruct [:tracks, :pagination]

  @type t() :: %__MODULE__{
          tracks: [Lilac.Track.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Track.t()], %Absinthe.Resolution{}, Lilac.Track.Filters.t()) :: t()
  def generate(tracks, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Tracks.count(filters),
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
