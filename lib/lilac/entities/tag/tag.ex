defmodule Lilac.Tag do
  use Ecto.Schema

  schema "tags" do
    field :name, :string

    many_to_many :artists, Lilac.Artist, join_through: "artist_tags"
  end
end

defmodule Lilac.Tag.Filters do
  defstruct [:artists, :keyword, :pagination, :fetch_tags_for_missing, :inputs]

  @type t() :: %__MODULE__{
          artists: [Lilac.Artist.Input.t()] | nil,
          keyword: binary | nil,
          pagination: Lilac.Pagination.Input.t() | nil,
          fetch_tags_for_missing: boolean | nil,
          inputs: [Lilac.Tag.Input.t()] | nil
        }
end
