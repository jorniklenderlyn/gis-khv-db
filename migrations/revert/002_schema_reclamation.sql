-- Revert gis-storage:002_schema_reclamation from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP SCHEMA reclamation;

COMMIT;
