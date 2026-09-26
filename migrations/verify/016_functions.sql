-- Verify gis-storage:016_functions on pg

BEGIN;

-- ::regprocedure падает, если функции нет
SELECT 'vegetation.ndvi_weekly_avg(integer, text, integer[], integer, integer)'::regprocedure;

ROLLBACK;
