-- Revert gis-storage:014_table_reclamation-systems from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE reclamation.reclamation_systems;

COMMIT;
