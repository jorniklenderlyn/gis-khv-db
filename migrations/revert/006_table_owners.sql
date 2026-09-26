-- Revert gis-storage:005_accounting_owner from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE accounting.owners;

COMMIT;
