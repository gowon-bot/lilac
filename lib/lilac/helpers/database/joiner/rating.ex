defmodule Lilac.Joiner.Rating do
  import Ecto.Query, only: [join: 5, select_merge: 3]

  alias Lilac.RYM.Rating

  @spec join_rym_album(Ecto.Query.t(), boolean) :: Ecto.Query.t()
  def join_rym_album(query, select) do
    joined_query =
      join(query, :left, [rating: r], l in assoc(r, :rate_your_music_album),
        as: :rate_your_music_album
      )

    if select do
      joined_query |> select_merge([rate_your_music_album: l], %{rate_your_music_album: l})
    else
      joined_query
    end
  end

  @spec maybe_join_user(Ecto.Query.t(), Rating.Filters.t()) :: Ecto.Query.t()
  def maybe_join_user(query, filters) do
    if Rating.Filters.has_user?(filters) do
      join(query, :left, [rating: r], u in assoc(r, :user), as: :user)
    else
      query
    end
  end
end
