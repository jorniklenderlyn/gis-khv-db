-- Verify gis-storage:006_table_districts on pg

BEGIN;

SELECT id, name, note
FROM accounting.districts
WHERE FALSE;

ROLLBACK;
