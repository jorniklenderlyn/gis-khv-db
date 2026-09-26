-- Revert gis-storage:013_table_media from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE vegetation.media;

COMMIT;
