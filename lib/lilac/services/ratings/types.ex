defmodule Lilac.Ratings.Parse.Types do
  defmodule RawRatingRow do
    defstruct [
      :rym_id,
      :artist_name,
      :artist_name_localized,
      :title,
      :release_year,
      :rating
    ]

    @type t() :: %__MODULE__{
            rym_id: String.t(),
            artist_name: String.t() | nil,
            artist_name_localized: String.t() | nil,
            title: String.t(),
            release_year: integer(),
            rating: float()
          }
  end
end
