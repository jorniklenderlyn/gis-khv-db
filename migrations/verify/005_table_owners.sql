-- Verify gis-storage:005_accounting_owner on pg

BEGIN;

SELECT
    id,
    name,
    note
FROM accounting.owners
WHERE FALSE;

SELECT
    conname,
    contype
FROM pg_constraint
WHERE conrelid = 'accounting.owners'::regclass
ORDER BY conname;

ROLLBACK;
