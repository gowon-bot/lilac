defmodule Lilac.Database.CustomFunctions do
  import Ecto.Query, only: [from: 2]

  @spec albums_in(term, [Lilac.Album.queryable()]) :: term
  def albums_in(query, albums) do
    Enum.reduce(albums, query, fn album, query ->
      from l in query, or_where: l.name == ^album.name and l.artist_id == ^album.artist_id
    end)
  end
end
