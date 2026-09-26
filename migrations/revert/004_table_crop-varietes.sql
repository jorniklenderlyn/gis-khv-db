-- Revert gis-storagef:003_table_crop-varietes from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE accounting.crop_varieties;

COMMIT;
