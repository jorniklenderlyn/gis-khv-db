-- Revert gis-storagef:003_table_crop-varietes from pg

BEGIN;

DROP TABLE accounting.crop_varieties;

COMMIT;
