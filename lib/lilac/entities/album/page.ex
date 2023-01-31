defmodule Lilac.Album.Page do
  defstruct [:albums, :pagination]

  @type t() :: %__MODULE__{
          albums: [Lilac.Album.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Album.t()], %Absinthe.Resolution{}, Lilac.Album.Filters.t()) :: t()
  def generate(albums, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Albums.count(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      albums: albums,
      pagination: pagination
    }
  end
end
