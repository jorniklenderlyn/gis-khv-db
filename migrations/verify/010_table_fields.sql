-- Verify gis-storage:011_table_fields on pg

BEGIN;

SELECT id, geom, registr_number, intern_number, district_id, owner_id,
       area, type_usage_plan_id, type_usage_fact_id, crop_plan_id, crop_fact_id,
       crop_variety_plan_id, crop_variety_fact_id, biochem_fact, harvest_fact,
       harvest_forecast, pesticides, fertilizers, sowing_date, harvest_date,
       inspected, hash, reclamation_system_id, note
FROM vegetation.fields
WHERE FALSE;

ROLLBACK;
