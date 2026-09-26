-- Revert gis-storage:006_table_districts from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE accounting.districts;

COMMIT;
