# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Lilac.Repo.insert!(%Lilac.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Lilac.{Artist, Album, Track}
alias Lilac.Repo

%Artist{name: "Red Velvet"} |> Repo.insert!()
wjsn = %Artist{name: "WJSN"} |> Repo.insert!()
jpegmafia = %Artist{name: "JPEGMAFIA"} |> Repo.insert!()

wj_please = %Album{name: "WJ Please?", artist: wjsn} |> Repo.insert!()
%Album{name: "All My Heroes Are Cornballs", artist: jpegmafia} |> Repo.insert!()

%Track{name: "You Got", artist: wjsn, album: wj_please} |> Repo.insert!()
