-- Deploy gis-storage:017_privileges to pg

BEGIN;

SET LOCAL ROLE gis_owner;

-- see docs/privileges_matrix.ods
GRANT USAGE ON SCHEMA accounting, vegetation, reclamation
    TO gis_app, gis_edit, gis_read;

-- existing tables
GRANT SELECT, INSERT, UPDATE, DELETE
    ON ALL TABLES IN SCHEMA accounting, vegetation, reclamation
    TO gis_app, gis_edit;

GRANT SELECT
    ON ALL TABLES IN SCHEMA accounting, vegetation, reclamation
    TO gis_read;

-- future tables and partitions created by gis_owner
ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA accounting, vegetation, reclamation
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO gis_app, gis_edit;

ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA accounting, vegetation, reclamation
    GRANT SELECT ON TABLES TO gis_read;

COMMIT;
