-- Revert gis-storage:016_functions from pg

BEGIN;

DROP FUNCTION vegetation.ndvi_weekly_avg(INTEGER, TEXT, INTEGER [], INTEGER, INTEGER);

COMMIT;
