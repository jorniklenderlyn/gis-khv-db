-- Revert gis-storage:016_functions from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP FUNCTION vegetation.ndvi_weekly_avg(INTEGER, TEXT, INTEGER [], INTEGER, INTEGER);

COMMIT;
