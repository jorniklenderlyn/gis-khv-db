-- Revert gis-storage:015_triggers from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TRIGGER evi_points_trg_crop_plan ON vegetation.evi_points;
DROP TRIGGER evi_points_trg_geom ON vegetation.evi_points;
DROP TRIGGER ndvi_points_trg_crop_plan ON vegetation.ndvi_points;
DROP TRIGGER ndvi_points_trg_geom ON vegetation.ndvi_points;
DROP TRIGGER fields_trg_hash ON vegetation.fields;
DROP TRIGGER fields_trg_area ON vegetation.fields;

DROP FUNCTION vegetation.set_crop_plan();
DROP FUNCTION vegetation.set_point_geom();
DROP FUNCTION vegetation.set_hash();
DROP FUNCTION vegetation.set_area();

COMMIT;
