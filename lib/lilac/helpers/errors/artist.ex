defmodule Lilac.Errors.Artist do
  def artist_doesnt_exist do
    {:error, "That artist doesn't exist on Last.fm!"}
  end
end
