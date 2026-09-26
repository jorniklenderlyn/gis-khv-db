-- bootstrap/region/database_access.sql
-- Runs as superuser inside the region database. Idempotent.

-- Deny by default: PUBLIC gets no access to the region database.
DO $$
BEGIN
    EXECUTE format('REVOKE ALL ON DATABASE %I FROM PUBLIC', current_database());
    EXECUTE format(
        'GRANT CONNECT ON DATABASE %I TO gis_app, gis_edit, gis_read',
        current_database()
    );
END
$$;

-- PG < 15 grants CREATE on schema public to PUBLIC by default.
-- USAGE stays: PostGIS types and functions live in public.
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
