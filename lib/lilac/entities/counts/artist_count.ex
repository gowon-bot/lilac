defmodule Lilac.ArtistCount do
  use Ecto.Schema

  schema("artist_counts") do
    field(:playcount, :integer)
    field(:first_scrobbled, :utc_datetime)
    field(:last_scrobbled, :utc_datetime)

    belongs_to :artist, Lilac.Artist
    belongs_to :user, Lilac.User
  end

  defmodule Page do
    defstruct [:artist_counts, :pagination]

    @type t() :: %__MODULE__{
            artist_counts: [Lilac.ArtistCount.t()],
            pagination: Lilac.Pagination.t()
          }

    @spec generate([Lilac.ArtistCount.t()], %Absinthe.Resolution{}, Lilac.ArtistCount.Filters.t()) ::
            t()
    def generate(artist_counts, info, filters) do
      pagination =
        if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
          do:
            Lilac.Pagination.generate(
              Lilac.Services.Artists.count_counts(filters),
              Map.get(filters, :pagination)
            ),
          else: %Lilac.Pagination{}
        )

      %__MODULE__{
        artist_counts: artist_counts,
        pagination: pagination
      }
    end
  end

  defmodule Filters do
    defstruct [:inputs, :tags, :users, :pagination, :fetch_tags_for_missing]

    @type t() :: %__MODULE__{
            inputs: [Lilac.Artist.Input.t()] | nil,
            tags: [Lilac.Tag.Input.t()] | nil,
            users: [Lilac.User.Input.t()],
            pagination: Lilac.Pagination.Input.t() | nil,
            fetch_tags_for_missing: boolean | nil
          }
  end
end
