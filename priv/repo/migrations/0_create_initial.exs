defmodule Lilac.Repo.Migrations.CreateInitial do
  use Ecto.Migration

  def change do
    # Extensions
    execute("CREATE EXTENSION IF NOT EXISTS citext", "DROP EXTENSION IF EXISTS citext")

    # Tables
    create table(:users) do
      add :discord_id, :string, null: false
      add :username, :string, null: false
      add :last_indexed, :naive_datetime
      add :last_fm_session, :string
      add :privacy, :integer, default: 5, null: false

      timestamps()
    end

    create table(:artists) do
      add :name, :citext, null: false
      add :checked_for_tags, :boolean, default: false, null: false
    end

    create table(:albums) do
      add :name, :citext, null: false

      add :artist_id, references(:artists), null: false
    end

    create table(:tracks) do
      add :name, :citext

      add :artist_id, references(:artists), null: false
      add :album_id, references(:albums), null: true
    end

    create table(:scrobbles) do
      add :scrobbled_at, :naive_datetime, null: true

      add :user_id, references(:users), null: false
      add :artist_id, references(:artists), null: false
      add :album_id, references(:albums), null: true
      add :track_id, references(:tracks), null: false
    end

    # Counts
    create table(:artist_counts) do
      add :playcount, :integer, null: false

      add :artist_id, references(:artists), null: false
      add :user_id, references(:users), null: false
    end

    create table(:album_counts) do
      add :playcount, :integer, null: false

      add :album_id, references(:albums), null: false
      add :user_id, references(:users), null: false
    end

    create table(:track_counts) do
      add :playcount, :integer, null: false

      add :track_id, references(:tracks), null: false
      add :user_id, references(:users), null: false
    end

    # Ratings
    create table(:rate_your_music_albums) do
      add :rate_your_music_id, :string, null: false
      add :release_year, :integer, null: false
      add :title, :string, null: false
      add :artist_name, :string, null: false
      add :artist_native_name, :string, null: false
    end

    create table(:rate_your_music_album_albums) do
      add :rate_your_music_album_id, references(:rate_your_music_albums), null: false
      add :album_id, references(:albums), null: false
    end

    create table(:ratings) do
      add :rating, :integer, null: false
      add :rate_your_music_album_id, references(:rate_your_music_albums), null: false

      add :user_id, references(:users), null: false
    end

    # Tags
    create table(:tags) do
      add :name, :text, null: false
    end

    create table(:artist_tags) do
      add :artist_id, references(:artists), null: false
      add :tag_id, references(:tags), null: false
    end

    # Misc
    create table(:guild_members) do
      add :guild_id, :string, null: false

      add :user_id, references(:users), null: false
    end

    # Indeces
    create index(:albums, [:artist_id], name: :al_artist_id_idx)
    create index(:albums, [:name], name: :al_name_idx)

    create index(:artists, [:name], name: :ar_name_idx)
    create index(:artist_counts, [:artist_id], name: :ac_artist_id_idx)
    create index(:artist_tags, [:tag_id], name: :idx_artist_tags_tag_id)

    create index(:guild_members, [:user_id], name: :gm_user_id)

    create index(:rate_your_music_albums, [:rate_your_music_id],
             name: :rymsl_rate_your_music_id_idx
           )

    create index(:rate_your_music_album_albums, [:album_id], name: :rymsll_album_id_idx)

    create index(:scrobbles, [:user_id], name: :scrobbles_user_id_idx)

    create index(:tracks, [:artist_id], name: :tr_artist_id_idx)
    create index(:tracks, [:name], name: :tr_name_idx)
    create index(:track_counts, [:track_id], name: :tc_track_id_idx)

    # Constraints
    create unique_index(:guild_members, [:guild_id, :user_id], name: :gm_uniqueness)
  end
end
