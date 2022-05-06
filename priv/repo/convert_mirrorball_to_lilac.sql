-- A note about this script:
-- This script was used to convert the old mirrorball database to work with Lilac,
-- as well as clean some stuff up
-- 
-- 
-- New changes are made to the database through migrations,
-- the schema described in this file is NOT final
-- 
-- -------------
-- USERS
-- -------------
-- No more user type in Lilac
ALTER TABLE
  users DROP COLUMN user_type;

-- Add timestamp columns to users
ALTER TABLE
  users
ADD
  COLUMN inserted_at TIMESTAMP(0) WITHOUT TIME ZONE,
ADD
  COLUMN updated_at TIMESTAMP(0) WITHOUT TIME ZONE;

-- Change privacy from enum to integer
-- private: 1, discord: 2, fm_username: 3, both: 4, unset: 5
ALTER TABLE
  users
ALTER COLUMN
  privacy
SET
  DATA TYPE INTEGER USING CASE
    WHEN privacy = 'PRIVATE' :: privacy THEN 1
    WHEN privacy = 'DISCORD' :: privacy THEN 2
    WHEN privacy = 'FMUSERNAME' :: privacy THEN 3
    WHEN privacy = 'BOTH' :: privacy THEN 4
    ELSE 5
  END;

DROP TYPE privacy;

-- -------------
-- SCROBBLES
-- -------------
-- "plays" was an uncessary abstraction, so was renamed to "scrobbles"
ALTER TABLE
  plays RENAME TO scrobbles;

-- We can simply drop the time zone since all scrobbles are already in UTC
ALTER TABLE
  scrobbles
ALTER COLUMN
  scrobbled_at
SET
  DATA TYPE TIMESTAMP WITHOUT TIME ZONE;

-- Rename indexes
ALTER INDEX "play_scrobbled_at_idx" RENAME TO "scrobbles_scrobbled_at_idx";

ALTER INDEX "play_track_id_idx" RENAME TO "scrobbles_track_id_idx";

ALTER INDEX "plays_pkey" RENAME TO "scrobbles_pkey";

-- Add artist and album ids to scrobbles
ALTER TABLE
  scrobbles
ADD
  COLUMN artist_id INTEGER REFERENCES artists(id),
ADD
  COLUMN album_id INTEGER REFERENCES albums(id);

-- "Update" the scrobbles table by creating a new table and replacing it
CREATE TABLE new_scrobbles (
  id SERIAL,
  scrobbled_at TIMESTAMP,
  user_id INTEGER,
  track_id INTEGER,
  album_id INTEGER,
  artist_id INTEGER
);

-- Insert into that new table
INSERT INTO
  new_scrobbles (
    id,
    scrobbled_at,
    user_id,
    track_id,
    album_id,
    artist_id
  ) (
    SELECT
      s.id,
      s.scrobbled_at,
      s.user_id,
      s.track_id,
      t.album_id,
      t.artist_id
    FROM
      scrobbles s
      JOIN tracks t ON t.id = s.track_id
  );

-- Add constraints and indexes back to the scrobbles table
ALTER TABLE
  new_scrobbles
ADD
  CONSTRAINT scrobbles_pk PRIMARY KEY (id);

CREATE INDEX new_scrobbles_scrobbled_at_idx ON new_scrobbles(scrobbled_at);

CREATE INDEX new_scrobbles_track_id_idx ON new_scrobbles(track_id);

ALTER TABLE
  new_scrobbles
ADD
  CONSTRAINT scrobbles_track_id_fkey FOREIGN KEY (track_id) REFERENCES tracks(id),
ADD
  CONSTRAINT scrobbles_user_id_fkey FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
ADD
  CONSTRAINT new_scrobbles_album_id_fkey FOREIGN KEY (album_id) REFERENCES albums(id),
ADD
  CONSTRAINT new_scrobbles_artist_id_fkey FOREIGN KEY (artist_id) REFERENCES artists(id);

-- 
-- DANGER ZONE
-- 
DROP TABLE scrobbles;

-- Rename new table to be the same as the old one
ALTER TABLE
  new_scrobbles RENAME TO scrobbles;