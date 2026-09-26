-- Revert gis-storagef:002_table_crops from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE accounting.crops;

COMMIT;
