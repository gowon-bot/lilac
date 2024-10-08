defmodule Lilac.AlbumCount do
  use Ecto.Schema

  schema("album_counts") do
    field(:playcount, :integer)
    field(:first_scrobbled, :utc_datetime)
    field(:last_scrobbled, :utc_datetime)

    belongs_to(:album, Lilac.Album)
    belongs_to(:user, Lilac.User)
  end

  defmodule Page do
    defstruct [:album_counts, :pagination]

    @type t() :: %__MODULE__{
            album_counts: [Lilac.AlbumCount.t()],
            pagination: Lilac.Pagination.t()
          }

    @spec generate([Lilac.AlbumCount.t()], %Absinthe.Resolution{}, Lilac.AlbumCount.Filters.t()) ::
            t()
    def generate(album_counts, info, filters) do
      pagination =
        if(Lilac.GraphQLHelpers.Introspection.requested_pagination?(info),
          do:
            Lilac.Pagination.generate(
              Lilac.Services.Albums.count_counts(filters),
              Map.get(filters, :pagination)
            ),
          else: %Lilac.Pagination{}
        )

      %__MODULE__{
        album_counts: album_counts,
        pagination: pagination
      }
    end
  end

  defmodule Filters do
    defstruct [:album, :users, :pagination]

    @type t() :: %__MODULE__{
            album: Lilac.Album.Input.t() | nil,
            users: [Lilac.User.Input.t()],
            pagination: Lilac.Pagination.Input.t() | nil
          }

    @spec has_users?(%__MODULE__{}) :: boolean()
    def has_users?(filters) do
      Map.has_key?(filters, :users)
    end

    @spec has_album?(%__MODULE__{}) :: boolean()
    def has_album?(filters) do
      Map.has_key?(filters, :album)
    end
  end
end
