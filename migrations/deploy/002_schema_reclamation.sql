-- Deploy gis-storage:002_schema_reclamation to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE SCHEMA reclamation AUTHORIZATION gis_owner;

COMMIT;
