-- Verify gis-storagef:003_table_crop-varietes on pg

BEGIN;

SELECT 'accounting.crop_varieties'::regclass;

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_pk';

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_uq_name_crop';

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_fk_crop';

ROLLBACK;
