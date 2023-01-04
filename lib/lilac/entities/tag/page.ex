defmodule Lilac.Tag.Page do
  defstruct [:tags, :pagination]

  @type t() :: %__MODULE__{
          tags: [Lilac.Tag.t()],
          pagination: Lilac.Pagination.t()
        }

  @spec generate([Lilac.Tag.t()], %Absinthe.Resolution{}, Lilac.Tag.Filters.t()) :: t()
  def generate(tags, info, filters) do
    pagination =
      if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
        do:
          Lilac.Pagination.generate(
            Lilac.Services.Tags.count(filters),
            Map.get(filters, :pagination)
          ),
        else: %Lilac.Pagination{}
      )

    %__MODULE__{
      tags: tags,
      pagination: pagination
    }
  end
end
