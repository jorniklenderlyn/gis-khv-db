-- Verify gis-storagef:002_table_crops on pg

BEGIN;

SELECT id, name, color, note
FROM accounting.crops
WHERE FALSE;

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crops'::regclass
  AND conname = 'crops_pk';

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crops'::regclass
  AND conname = 'crops_uq_color';

SELECT 1
FROM pg_constraint
WHERE conrelid = 'accounting.crops'::regclass
  AND conname = 'crops_uq_name';

ROLLBACK;
