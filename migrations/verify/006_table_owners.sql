-- Verify gis-storage:005_accounting_owner on pg

BEGIN;

SELECT id, name, note
FROM accounting.owners
WHERE FALSE;

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.owners'::regclass
  AND conname = 'owners_pk';

SELECT 1 / count(*)
FROM pg_constraint
WHERE conrelid = 'accounting.owners'::regclass
  AND conname = 'owners_uq_name';

ROLLBACK;
