-- Verify gis-storage:017_privileges on pg

BEGIN;

-- (count(*) = 0)::int is 0 when something is wrong -> division by zero

-- every table, function and sequence in project schemas is owned by gis_owner
-- (catches a migration that forgot SET LOCAL ROLE gis_owner)
SELECT 1 / (count(*) = 0)::int
FROM pg_class AS c
INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
WHERE n.nspname IN ('accounting', 'vegetation', 'reclamation')
  AND c.relowner <> 'gis_owner'::regrole;

SELECT 1 / (count(*) = 0)::int
FROM pg_proc AS p
INNER JOIN pg_namespace AS n ON n.oid = p.pronamespace
WHERE n.nspname IN ('accounting', 'vegetation', 'reclamation')
  AND p.proowner <> 'gis_owner'::regrole;

-- schema usage
SELECT 1 / (count(*) = 0)::int
FROM unnest(ARRAY['accounting', 'vegetation', 'reclamation']) AS s (name)
CROSS JOIN unnest(ARRAY['gis_app', 'gis_edit', 'gis_read']) AS r (name)
WHERE NOT has_schema_privilege(r.name, s.name, 'USAGE');

-- gis_read: SELECT on every table, no writes
SELECT 1 / (count(*) = 0)::int
FROM pg_tables AS t
WHERE t.schemaname IN ('accounting', 'vegetation', 'reclamation')
  AND (
      NOT has_table_privilege('gis_read', format('%I.%I', t.schemaname, t.tablename), 'SELECT')
      OR has_table_privilege('gis_read', format('%I.%I', t.schemaname, t.tablename), 'INSERT, UPDATE, DELETE')
  );

-- gis_app, gis_edit: SELECT, INSERT, UPDATE, DELETE on every table, no TRUNCATE
SELECT 1 / (count(*) = 0)::int
FROM pg_tables AS t
CROSS JOIN unnest(ARRAY['gis_app', 'gis_edit']) AS r (name)
CROSS JOIN unnest(ARRAY['SELECT', 'INSERT', 'UPDATE', 'DELETE']) AS p (name)
WHERE t.schemaname IN ('accounting', 'vegetation', 'reclamation')
  AND NOT has_table_privilege(r.name, format('%I.%I', t.schemaname, t.tablename), p.name);

SELECT 1 / (count(*) = 0)::int
FROM pg_tables AS t
CROSS JOIN unnest(ARRAY['gis_app', 'gis_edit']) AS r (name)
WHERE t.schemaname IN ('accounting', 'vegetation', 'reclamation')
  AND has_table_privilege(r.name, format('%I.%I', t.schemaname, t.tablename), 'TRUNCATE');

-- default privileges exist for all three schemas
SELECT 1 / (count(*) = 3)::int
FROM pg_default_acl AS d
INNER JOIN pg_namespace AS n ON n.oid = d.defaclnamespace
WHERE d.defaclrole = 'gis_owner'::regrole
  AND d.defaclobjtype = 'r'
  AND n.nspname IN ('accounting', 'vegetation', 'reclamation');

ROLLBACK;
