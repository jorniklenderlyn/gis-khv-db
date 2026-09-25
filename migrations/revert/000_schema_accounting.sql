-- Revert gis-storage:000_schema_accounting from pg

BEGIN;

DROP SCHEMA accounting;

COMMIT;
