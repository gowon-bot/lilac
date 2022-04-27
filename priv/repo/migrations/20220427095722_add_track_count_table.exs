defmodule Lilac.Repo.Migrations.AddTrackCountTable do
  use Ecto.Migration

  def change do
    create table(:track_counts) do
      add :playcount, :integer

      add :track_id, references(:tracks)
      add :user_id, references(:users)
    end
  end
end
