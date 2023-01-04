defmodule Lilac.Scrobble.Page do
  defstruct [:scrobbles, :pagination]

  @type t() :: %__MODULE__{
          scrobbles: [Lilac.Scrobble.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Scrobble.t()], %Absinthe.Resolution{}, Lilac.Scrobble.Filters.t()) :: t()
  def generate(scrobbles, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Scrobbles.count(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      scrobbles: scrobbles,
      pagination: pagination
    }
  end
end
