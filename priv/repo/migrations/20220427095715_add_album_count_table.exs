defmodule Lilac.Repo.Migrations.AddAlbumCountTable do
  use Ecto.Migration

  def change do
    create table(:album_counts) do
      add :playcount, :integer

      add :album_id, references(:albums)
      add :user_id, references(:users)
    end
  end
end
