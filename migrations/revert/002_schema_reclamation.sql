-- Revert gis-storage:002_schema_reclamation from pg

BEGIN;

DROP SCHEMA reclamation;

COMMIT;
