-- Deploy gis-storage:001_schema_gis-vegetation to pg

BEGIN;

CREATE SCHEMA vegetation AUTHORIZATION gis_owner;

COMMIT;
