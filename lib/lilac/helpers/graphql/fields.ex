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

  defmodule Artist do
    def tags, do: ["artists", "tags"]

    defmodule Count do
      def tags, do: ["artistCounts", "tags"]
    end
  end

  defmodule Album do
    defmodule Count do
      def user, do: ["albumCounts", "user"]

      def album, do: ["albumCounts", "album"]
      def album_artist, do: ["albumCounts", "album", "artist"]
    end
  end
end
