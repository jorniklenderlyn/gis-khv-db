-- Revert gis-storage:001_schema_gis-vegetation from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP SCHEMA vegetation;

COMMIT;
