-- Revert gis-storage:007_table_models from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE accounting.models;

COMMIT;
