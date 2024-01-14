defmodule Lilac.GraphQLHelpers.Fields do
  def pagination, do: "pagination"

  defmodule Filters do
    def pagination, do: ["filters", "pagination"]
  end

  defmodule User do
    def is_syncing, do: "isSyncing"
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
    def artist, do: ["albums", "artist"]

    defmodule Count do
      def user, do: ["albumCounts", "user"]

      def album, do: ["albumCounts", "album"]
      def album_artist, do: ["albumCounts", "album", "artist"]
    end
  end

  defmodule Track do
    def artist, do: ["tracks", "artist"]
    def album, do: ["tracks", "album"]

    defmodule Count do
      def user, do: ["trackCounts", "user"]

      def track, do: ["trackCounts", "track"]
      def artist, do: ["trackCounts", "track", "artist"]
      def album, do: ["trackCounts", "track", "album"]
    end
  end
end
