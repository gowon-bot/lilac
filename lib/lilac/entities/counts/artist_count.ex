defmodule Lilac.ArtistCount do
  use Ecto.Schema

  schema("artist_counts") do
    field :playcount, :integer

    belongs_to :artist, Lilac.Artist
    belongs_to :user, Lilac.User
  end

  defmodule Page do
    defstruct [:artist_counts, :pagination]

    @type t() :: %__MODULE__{
            artist_counts: [Lilac.ArtistCount.t()],
            pagination: Lilac.Pagination.t()
          }
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
