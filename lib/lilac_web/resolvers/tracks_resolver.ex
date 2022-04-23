defmodule LilacWeb.Resolvers.Tracks do
  import Ecto.Query, only: [from: 2]

  def all_tracks(_root, _args, _info) do
    query =
      from l in Lilac.Track,
        preload: [:artist, :album]

    {:ok, query |> Lilac.Repo.all()}
  end
end
