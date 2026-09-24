-- Revert gis-storagef:001_schema_gis-vegetation from pg

BEGIN;

DROP SCHEMA gis_vegetation;

COMMIT;
