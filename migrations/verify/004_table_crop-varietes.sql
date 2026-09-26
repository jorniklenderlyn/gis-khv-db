-- Verify gis-storagef:003_table_crop-varietes on pg

BEGIN;

SELECT id, name, note, crop_id
FROM accounting.crop_varieties
WHERE FALSE;

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_pk';

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_uq_name_crop';

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.crop_varieties'::regclass
  AND conname = 'crop_varieties_fk_crop_id';

ROLLBACK;
