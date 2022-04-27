defmodule Lilac.CountingHelpers do
  @type any_count :: %Lilac.ArtistCount{}

  def changeset(count, increment) do
    Ecto.Changeset.change(count, playcount: count.playcount + increment)
  end
end
