-- Revert gis-storage:007_table_models from pg

BEGIN;

DROP TABLE accounting.models;

COMMIT;
