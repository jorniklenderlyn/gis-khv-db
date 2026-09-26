-- Revert gis-storage:011_table_fields from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE vegetation.fields;

COMMIT;
