defmodule Lilac.Repo.Migrations.AddArtistCountTable do
  use Ecto.Migration

  def change do
    create table(:artist_counts) do
      add :playcount, :integer

      add :artist_id, references(:artists)
      add :user_id, references(:users)
    end
  end
end
