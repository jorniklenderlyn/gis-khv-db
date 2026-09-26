-- Revert gis-storagef:004_table_usage-types from pg

BEGIN;


DROP TABLE accounting.usage_types;

COMMIT;
