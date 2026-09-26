-- Deploy gis-storage:000_schema_accounting to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE SCHEMA accounting AUTHORIZATION gis_owner;

COMMIT;
