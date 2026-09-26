-- Verify gis-storage:001_schema_gis-vegetation on pg

BEGIN;

SELECT 'vegetation'::regnamespace;

ROLLBACK;
