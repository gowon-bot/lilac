defmodule Lilac.RYM.Rating.Filters do
  defstruct [:user, :album, :pagination, :rating]

  @type t() :: %__MODULE__{
          user: Lilac.User.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil,
          pagination: Lilac.Pagination.t() | nil,
          rating: integer() | nil
        }

  def has_user?(filters) do
    Map.has_key?(filters, :user) || Map.has_key?(filters, :users)
  end
end
