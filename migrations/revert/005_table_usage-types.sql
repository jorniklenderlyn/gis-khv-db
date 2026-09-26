-- Revert gis-storagef:004_table_usage-types from pg

BEGIN;

SET LOCAL ROLE gis_owner;


DROP TABLE accounting.usage_types;

COMMIT;
