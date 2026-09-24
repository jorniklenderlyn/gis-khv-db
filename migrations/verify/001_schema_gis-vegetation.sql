-- Verify gis-storagef:001_schema_gis-vegetation on pg

BEGIN;

SELECT 1
FROM pg_namespace
WHERE nspname = 'gis-vegetation';

ROLLBACK;
