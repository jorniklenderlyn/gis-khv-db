-- Deploy gis-storage:000_schema_accounting to pg

BEGIN;

CREATE SCHEMA accounting AUTHORIZATION gis_owner;

COMMIT;
