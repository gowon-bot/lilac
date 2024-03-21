defmodule Lilac.RYM.Rating do
  use Ecto.Schema

  @timestamps_opts [type: :utc_datetime]

  schema "ratings" do
    field :rating, :integer

    belongs_to :user, Lilac.User
    belongs_to :rate_your_music_album, Lilac.RYM.Album, foreign_key: :rate_your_music_album_id
  end
end
