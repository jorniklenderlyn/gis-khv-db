-- data-migration/06_sequences.sql
-- Moves every identity sequence in the project schemas past the migrated ids,
-- so the next generated id does not collide with a legacy one.
-- Run as superuser in the region database after 05_media_analysis.sql:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/06_sequences.sql

\set ON_ERROR_STOP on
\pset footer off

BEGIN;

CREATE TEMP TABLE sequences_report (tbl TEXT, max_id BIGINT, next_id BIGINT);

DO $$
DECLARE
    t RECORD;
    max_id BIGINT;
BEGIN
    -- identity columns of tables and partitioned parents (partitions share the parent's sequence)
    FOR t IN
        SELECT format('%I.%I', n.nspname, c.relname) AS tbl, a.attname AS col
        FROM pg_attribute AS a
        INNER JOIN pg_class AS c ON c.oid = a.attrelid
        INNER JOIN pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname IN ('accounting', 'vegetation', 'reclamation')
          AND c.relkind IN ('r', 'p')
          AND NOT c.relispartition
          AND a.attidentity <> ''
        ORDER BY 1
    LOOP
        EXECUTE format('SELECT max(%I) FROM %s', t.col, t.tbl) INTO max_id;
        -- empty table: next id is 1; otherwise max + 1
        PERFORM setval(pg_get_serial_sequence(t.tbl, t.col), coalesce(max_id, 1), max_id IS NOT NULL);
        INSERT INTO sequences_report VALUES (t.tbl, max_id, coalesce(max_id + 1, 1));
    END LOOP;
END
$$;

SELECT tbl, max_id, next_id FROM sequences_report ORDER BY tbl;

COMMIT;
