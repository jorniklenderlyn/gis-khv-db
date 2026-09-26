-- Verify gis-storage:002_schema_reclamation on pg

BEGIN;

SELECT 'reclamation'::regnamespace;

ROLLBACK;
