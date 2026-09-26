-- Revert gis-storage:010_table_evi-points from pg

BEGIN;

DROP TABLE vegetation.evi_points;

COMMIT;
