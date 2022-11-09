defmodule Lilac.Repo.Migrations.ChangeTagNameToCitext do
  use Ecto.Migration

  def change do
    alter table(:tags) do
      modify :name, :citext
    end
  end
end
