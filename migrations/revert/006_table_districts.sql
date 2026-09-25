-- Revert gis-storage:006_table_districts from pg

BEGIN;

DROP TABLE accounting.districts;

COMMIT;
