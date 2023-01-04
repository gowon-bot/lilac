defmodule Lilac.Artist.Page do
  defstruct [:artists, :pagination]

  @type t() :: %__MODULE__{
          artists: [Lilac.Artist.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Artist.t()], %Absinthe.Resolution{}, Lilac.Artist.Filters.t()) :: t()
  def generate(artists, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Artists.count(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      artists: artists,
      pagination: pagination
    }
  end
end
