-- Verify gis-storage:000_schema_accounting on pg

BEGIN;

SELECT 'accounting'::regnamespace;

ROLLBACK;
