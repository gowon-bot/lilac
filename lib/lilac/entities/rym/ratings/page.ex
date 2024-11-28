defmodule Lilac.RYM.Rating.Page do
  alias Lilac.RYM
  alias Lilac.Ratings

  defstruct [:ratings, :pagination]

  @type t() :: %__MODULE__{
          ratings: [RYM.Rating.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([RYM.Rating.t()], %Absinthe.Resolution{}, RYM.Rating.Filters.t()) :: t()
  def generate(ratings, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Ratings.count(filters),
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
