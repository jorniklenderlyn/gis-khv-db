-- Verify gis-storage:014_table_reclamation-systems on pg

BEGIN;

SELECT id, name, area, year_commissioned, year_reconstructed, wear_percent,
       water_receiver, water_source, geom
FROM reclamation.reclamation_systems
WHERE FALSE;

ROLLBACK;
