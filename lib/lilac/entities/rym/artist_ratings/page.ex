defmodule Lilac.RYM.Artist.Rating.Page do
  alias Lilac.RYM
  alias Lilac.Ratings

  defstruct [:ratings, :pagination]

  @type t() :: %__MODULE__{
          ratings: [RYM.Artist.Rating.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([RYM.Artist.Rating.t()], %Absinthe.Resolution{}, RYM.Artist.Rating.Filters.t()) ::
          t()
  def generate(ratings, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Ratings.count_artist_ratings(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      ratings: ratings,
      pagination: pagination
    }
  end
end
