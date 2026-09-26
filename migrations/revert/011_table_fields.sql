-- Revert gis-storage:011_table_fields from pg

BEGIN;

DROP TABLE vegetation.fields;

COMMIT;
