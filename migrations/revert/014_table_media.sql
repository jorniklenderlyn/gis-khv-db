-- Revert gis-storage:013_table_media from pg

BEGIN;

DROP TABLE vegetation.media;

COMMIT;
