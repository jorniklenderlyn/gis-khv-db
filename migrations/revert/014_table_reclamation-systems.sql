-- Revert gis-storage:014_table_reclamation-systems from pg

BEGIN;

DROP TABLE reclamation.reclamation_systems;

COMMIT;
