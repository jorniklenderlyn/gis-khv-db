-- Verify gis-storagef:004_table_usage-types on pg

BEGIN;

SELECT 1
FROM information_schema.tables
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types';

SELECT 1
FROM information_schema.columns
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND column_name = 'id'
  AND data_type = 'integer';

SELECT 1
FROM information_schema.columns
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND column_name = 'name'
  AND data_type = 'character varying'
  AND is_nullable = 'NO';

SELECT 1
FROM information_schema.table_constraints
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND constraint_name = 'usage_types_pk'
  AND constraint_type = 'PRIMARY KEY';

SELECT 1
FROM information_schema.table_constraints
WHERE table_schema = 'accounting'
  AND table_name = 'usage_types'
  AND constraint_name = 'usage_types_uq_name'
  AND constraint_type = 'UNIQUE';

ROLLBACK;
