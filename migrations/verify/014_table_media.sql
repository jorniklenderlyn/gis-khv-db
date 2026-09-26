-- Verify gis-storage:013_table_media on pg

BEGIN;

SELECT id, field_id, reference, geom, filming_date, note
FROM vegetation.media
WHERE FALSE;

ROLLBACK;
