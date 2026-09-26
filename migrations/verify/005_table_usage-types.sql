-- Verify gis-storagef:004_table_usage-types on pg

BEGIN;

SELECT id, name, note
FROM accounting.usage_types
WHERE FALSE;

SELECT 1 / count(*)
FROM information_schema.columns
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND column_name = 'id'
  AND data_type = 'integer';

SELECT 1 / count(*)
FROM information_schema.columns
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND column_name = 'name'
  AND data_type = 'character varying'
  AND is_nullable = 'NO';

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.usage_types'::regclass
  AND conname = 'usage_types_pk';

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.usage_types'::regclass
  AND conname = 'usage_types_uq_name';

ROLLBACK;
