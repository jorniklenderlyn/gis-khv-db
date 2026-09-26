-- Verify gis-storage:007_table_models on pg

BEGIN;

SELECT id, name, note
FROM accounting.models
WHERE FALSE;

ROLLBACK;
