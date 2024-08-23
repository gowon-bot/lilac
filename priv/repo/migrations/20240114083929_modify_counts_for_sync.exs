defmodule Lilac.Repo.Migrations.ModifyCountsForSync do
  use Ecto.Migration

  def change do
    alter table(:artist_counts) do
      add(:first_scrobbled, :utc_datetime)
      add(:last_scrobbled, :utc_datetime)
    end

    alter table(:album_counts) do
      add(:first_scrobbled, :utc_datetime)
      add(:last_scrobbled, :utc_datetime)
    end

    alter table(:track_counts) do
      add(:first_scrobbled, :utc_datetime)
      add(:last_scrobbled, :utc_datetime)
    end
  end
end
