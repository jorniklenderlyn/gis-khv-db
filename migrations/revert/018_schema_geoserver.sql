-- Revert gis-storage:018_schema_geoserver from pg

BEGIN;

SET LOCAL ROLE gis_owner;

ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA geoserver
    REVOKE SELECT ON TABLES FROM gis_geoserver;

DROP VIEW geoserver.ndvi_points;
DROP VIEW geoserver.fields;

-- REVOKE не нужен: права на схему уходят вместе с ней.
DROP SCHEMA geoserver;

COMMIT;
