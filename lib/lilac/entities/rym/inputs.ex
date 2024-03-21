defmodule Lilac.RYM.Rating.Filters do
  defstruct [:user, :album, :pagination, :rating]

  @type t() :: %__MODULE__{
          user: Lilac.User.Input.t() | nil,
          album: Lilac.Album.Input.t() | nil,
          pagination: Lilac.Pagination.t() | nil,
          rating: integer() | nil
        }

  def has_user?(%{user: nil}), do: false
  def has_user?(%{user: _}), do: true
end
