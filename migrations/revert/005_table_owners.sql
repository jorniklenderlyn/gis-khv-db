-- Revert gis-storage:005_accounting_owner from pg

BEGIN;

DROP TABLE accounting.owners;

COMMIT;
