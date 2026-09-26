-- Revert gis-storage:000_schema_accounting from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP SCHEMA accounting;

COMMIT;
