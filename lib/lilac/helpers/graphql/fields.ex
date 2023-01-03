defmodule Lilac.GraphQLHelpers.Fields do
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
