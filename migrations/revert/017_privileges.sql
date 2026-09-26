-- Revert gis-storage:017_privileges from pg

BEGIN;

SET LOCAL ROLE gis_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA accounting, vegetation, reclamation
    REVOKE SELECT ON TABLES FROM gis_read;

ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA accounting, vegetation, reclamation
    REVOKE SELECT, INSERT, UPDATE, DELETE ON TABLES FROM gis_app, gis_edit;

REVOKE ALL
    ON ALL TABLES IN SCHEMA accounting, vegetation, reclamation
    FROM gis_app, gis_edit, gis_read;

REVOKE USAGE ON SCHEMA accounting, vegetation, reclamation
    FROM gis_app, gis_edit, gis_read;

COMMIT;
