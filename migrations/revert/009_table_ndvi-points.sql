-- Revert gis-storage:009_table_ndvi-points from pg

BEGIN;

DROP TABLE vegetation.ndvi_points;

COMMIT;
