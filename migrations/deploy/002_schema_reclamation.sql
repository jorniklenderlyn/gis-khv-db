-- Deploy gis-storage:002_schema_reclamation to pg

BEGIN;

CREATE SCHEMA reclamation AUTHORIZATION gis_owner;

COMMIT;
