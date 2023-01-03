defmodule Lilac.GraphQLHelpers.Fields do
  def pagination, do: "pagination"

  defmodule Filters do
    def pagination, do: ["filters", "pagination"]
  end

  defmodule User do
    def is_indexing, do: "isIndexing"
  end

  defmodule Scrobble do
    def artist, do: ["scrobbles", "artist"]
    def album, do: ["scrobbles", "album"]
    def track, do: ["scrobbles", "track"]
    def user, do: ["scrobbles", "user"]
  end
end
