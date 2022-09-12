defmodule Lilac.Errors.Entities do
  def artist_doesnt_exist do
    {:error, "That artist doesn't exist on Last.fm!"}
  end

  def album_doesnt_exist do
    {:error, "That album doesn't exist on Last.fm!"}
  end

  def track_doesnt_exist do
    {:error, "That track doesn't exist on Last.fm!"}
  end
end
