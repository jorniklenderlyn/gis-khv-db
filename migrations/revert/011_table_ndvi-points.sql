-- Revert gis-storage:009_table_ndvi-points from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE vegetation.ndvi_points;

COMMIT;
