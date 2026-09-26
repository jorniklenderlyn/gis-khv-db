-- Deploy gis-storage:001_schema_gis-vegetation to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE SCHEMA vegetation AUTHORIZATION gis_owner;

COMMIT;
