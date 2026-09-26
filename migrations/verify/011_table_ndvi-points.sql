-- Verify gis-storage:009_table_ndvi-points on pg

BEGIN;

SELECT id, year, pixel_size, version, geom, x, y, field_id, note
FROM vegetation.ndvi_points
WHERE FALSE;

ROLLBACK;
