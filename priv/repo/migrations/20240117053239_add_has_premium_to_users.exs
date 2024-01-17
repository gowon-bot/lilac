defmodule Lilac.Repo.Migrations.AddHasPremiumToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:has_premium, :boolean)
    end
  end
end
