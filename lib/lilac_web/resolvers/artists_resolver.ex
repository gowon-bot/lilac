defmodule LilacWeb.Resolvers.Artists do
  def all_artists(_root, _args, _info) do
    {:ok, Lilac.Artist |> Lilac.Repo.all()}
  end
end
