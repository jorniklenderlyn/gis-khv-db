-- Revert gis-storagef:002_table_crops from pg

BEGIN;

DROP TABLE accounting.crops;

COMMIT;
