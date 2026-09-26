-- Revert gis-storage:010_table_evi-points from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE vegetation.evi_points;

COMMIT;
