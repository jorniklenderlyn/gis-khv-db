-- Verify gis-storage:000_schema_accounting on pg

BEGIN;

SELECT 1
FROM pg_namespace
WHERE nspname = 'accounting';

ROLLBACK;
