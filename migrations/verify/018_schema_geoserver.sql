-- Verify gis-storage:018_schema_geoserver on pg

BEGIN;

-- (count(*) = 0)::int is 0 when something is wrong -> division by zero

SELECT id, year, geom, registr_number, area, district_id, district_name,
       crop_plan_id, crop_plan_name, crop_fact_id, crop_fact_name,
       crop_fact_color, type_usage_fact_id, inspected
FROM geoserver.fields
WHERE FALSE;

SELECT id, year, pixel_size, version, geom, field_id, crop_plan_id,
       crop_pixel_result_id, ndvi_week_01, ndvi_week_52
FROM geoserver.ndvi_points
WHERE FALSE;

-- everything in the schema is owned by gis_owner
SELECT 1 / (count(*) = 0)::int
FROM pg_class AS c
WHERE c.relnamespace = 'geoserver'::regnamespace
  AND c.relowner <> 'gis_owner'::regrole;

-- views run with owner rights: security_invoker would require
-- gis_geoserver to read the base tables
SELECT 1 / (count(*) = 0)::int
FROM pg_class AS c
WHERE c.relnamespace = 'geoserver'::regnamespace
  AND 'security_invoker=true' = ANY(COALESCE(c.reloptions, '{}'));

-- gis_geoserver: SELECT on every view in the schema, no writes
SELECT 1 / (count(*) = 0)::int
FROM pg_class AS c
WHERE c.relnamespace = 'geoserver'::regnamespace
  AND c.relkind IN ('r', 'v', 'm', 'p')
  AND (
      NOT has_table_privilege('gis_geoserver', c.oid, 'SELECT')
      OR has_table_privilege('gis_geoserver', c.oid, 'INSERT, UPDATE, DELETE, TRUNCATE')
  );

-- gis_geoserver sees nothing but the geoserver schema (and public for PostGIS)
SELECT 1 / (count(*) = 0)::int
FROM unnest(ARRAY['accounting', 'vegetation', 'reclamation']) AS s (name)
WHERE has_schema_privilege('gis_geoserver', s.name, 'USAGE');

SELECT 1 / has_schema_privilege('gis_geoserver', 'geoserver', 'USAGE')::int;

-- default privileges for future views
SELECT 1 / count(*)
FROM pg_default_acl AS d
WHERE d.defaclrole = 'gis_owner'::regrole
  AND d.defaclobjtype = 'r'
  AND d.defaclnamespace = 'geoserver'::regnamespace;

ROLLBACK;
