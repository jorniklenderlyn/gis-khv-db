-- data-migration/99_drop_legacy.sql
-- Drops legacy schemas ("Accounting" and "YYYY") restored by 00_restore_legacy.sh.
-- Run only after 07_reconcile.sql has passed:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/99_drop_legacy.sql

\set ON_ERROR_STOP on

BEGIN;

DO $$
DECLARE
    s TEXT;
BEGIN
    -- guard against dropping the only copy of the data before migration
    IF NOT EXISTS (SELECT FROM vegetation.fields) THEN
        RAISE EXCEPTION 'vegetation.fields is empty: migrate the data before dropping legacy schemas';
    END IF;

    FOR s IN
        SELECT nspname FROM pg_namespace
        WHERE nspname ~ '^(Accounting|[0-9]{4})$'
        ORDER BY 1
    LOOP
        EXECUTE format('DROP SCHEMA %I CASCADE', s);
        RAISE NOTICE 'dropped schema %', s;
    END LOOP;
END
$$;

COMMIT;
