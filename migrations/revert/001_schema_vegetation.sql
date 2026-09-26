-- Revert gis-storage:001_schema_gis-vegetation from pg

BEGIN;

DROP SCHEMA vegetation;

COMMIT;
