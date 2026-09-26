-- Verify gis-storage:002_schema_reclamation on pg

BEGIN;

SELECT 1
FROM pg_namespace
WHERE nspname = 'reclamation';

ROLLBACK;
