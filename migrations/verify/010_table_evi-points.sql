-- Verify gis-storage:010_table_evi-points on pg

BEGIN;

SELECT id, year, pixel_size, version, geom, x, y, field_id, note
FROM vegetation.evi_points
WHERE FALSE;

ROLLBACK;
