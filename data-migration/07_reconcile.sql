-- data-migration/07_reconcile.sql
-- Read-only comparison of legacy schemas and migrated data. Fails if anything differs.
-- Run as superuser in the region database after 06_sequences.sql:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/07_reconcile.sql
--
-- Not compared on purpose:
--   area, hash      - recomputed by triggers (legacy area may be in square degrees)
--   crop_plan_id    - recomputed from the field by the trigger
--   point/media/analysis ids - new ids are generated

\set ON_ERROR_STOP on
\pset footer off

CREATE TEMP TABLE reconcile (
    check_name TEXT, object TEXT, legacy NUMERIC, migrated NUMERIC, ok BOOLEAN
);

DO $$
DECLARE
    d RECORD;
    t RECORD;
    m TEXT[];
    y INTEGER;
    n_old NUMERIC;
    n_new NUMERIC;
    missing BIGINT;
    extra BIGINT;
    old_weeks TEXT;
    new_weeks TEXT;
    col_x TEXT;
    col_y TEXT;
BEGIN
    ------------------------------------------------------------------
    -- dictionaries: same ids
    ------------------------------------------------------------------
    FOR d IN
        SELECT * FROM (VALUES
            ('list_of_crops', 'accounting.crops'),
            ('list_of_crop_sorts', 'accounting.crop_varieties'),
            ('list_of_usage_types', 'accounting.usage_types'),
            ('list_of_owners', 'accounting.owners'),
            ('list_of_districts', 'accounting.districts'),
            ('list_of_models', 'accounting.models'),
            ('list_of_reclamation_systems', 'reclamation.reclamation_systems')
        ) AS v (legacy, target)
    LOOP
        CONTINUE WHEN to_regclass(format('"Accounting".%I', d.legacy)) IS NULL;
        EXECUTE format(
            'SELECT (SELECT count(*) FROM "Accounting".%I),
                    (SELECT count(*) FROM %s),
                    (SELECT count(*) FROM (SELECT id FROM "Accounting".%I EXCEPT SELECT id FROM %s) s),
                    (SELECT count(*) FROM (SELECT id FROM %s EXCEPT SELECT id FROM "Accounting".%I) s)',
            d.legacy, d.target, d.legacy, d.target, d.target, d.legacy)
        INTO n_old, n_new, missing, extra;
        INSERT INTO reconcile VALUES ('dictionary ids', d.target, n_old, n_new,
            n_old = n_new AND missing = 0 AND extra = 0);
    END LOOP;

    ------------------------------------------------------------------
    -- fields: same ids per year
    ------------------------------------------------------------------
    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_list_of_fields$'
        ORDER BY 1
    LOOP
        y := t.s::INTEGER;
        EXECUTE format(
            'SELECT (SELECT count(*) FROM %I.%I),
                    (SELECT count(*) FROM vegetation.fields WHERE year = %s),
                    (SELECT count(*) FROM (SELECT id FROM %I.%I
                                           EXCEPT SELECT id FROM vegetation.fields WHERE year = %s) s),
                    (SELECT count(*) FROM (SELECT id FROM vegetation.fields WHERE year = %s
                                           EXCEPT SELECT id FROM %I.%I) s)',
            t.s, t.tb, y, t.s, t.tb, y, y, t.s, t.tb)
        INTO n_old, n_new, missing, extra;
        INSERT INTO reconcile VALUES ('field ids', t.s || '.' || t.tb, n_old, n_new,
            n_old = n_new AND missing = 0 AND extra = 0);
    END LOOP;

    ------------------------------------------------------------------
    -- points: row count, every (x, y) present, sum of all weekly values
    ------------------------------------------------------------------
    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_(NDVI|EVI)_[0-9]+_[0-9]+$'
        ORDER BY 1, 2
    LOOP
        m := regexp_match(t.tb, '^([0-9]{4})_(NDVI|EVI)_([0-9]+)_([0-9]+)$');

        SELECT
            string_agg(format('coalesce(o.%s, 0)', quote_ident(c.column_name)), ' + '),
            string_agg(format('coalesce(n.%s_week_%s, 0)', lower(m[2]), lpad(w.i::TEXT, 2, '0')), ' + ')
        INTO old_weeks, new_weeks
        FROM generate_series(1, 52) AS w (i)
        JOIN information_schema.columns AS c
            ON c.table_schema = t.s AND c.table_name = t.tb
           AND lower(c.column_name) = CASE m[2] WHEN 'NDVI' THEN 'ndv' ELSE 'evi' END || w.i;

        SELECT
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'x'),
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'y')
        INTO col_x, col_y
        FROM information_schema.columns
        WHERE table_schema = t.s AND table_name = t.tb;

        EXECUTE format(
            'SELECT (SELECT count(*) FROM %I.%I),
                    (SELECT count(*) FROM vegetation.%I
                     WHERE year = %s AND pixel_size = %s AND version = %s)',
            t.s, t.tb, lower(m[2]) || '_points', m[1], m[3], m[4])
        INTO n_old, n_new;
        INSERT INTO reconcile VALUES ('point rows', t.s || '.' || t.tb, n_old, n_new, n_old = n_new);

        -- legacy points without a migrated point at the same coordinates
        EXECUTE format(
            'SELECT count(*) FROM %I.%I o
             WHERE NOT EXISTS (SELECT FROM vegetation.%I n
                               WHERE n.year = %s AND n.pixel_size = %s AND n.version = %s
                                 AND n.x = o.%s AND n.y = o.%s)',
            t.s, t.tb, lower(m[2]) || '_points', m[1], m[3], m[4], col_x, col_y)
        INTO missing;
        INSERT INTO reconcile VALUES ('point coordinates missing', t.s || '.' || t.tb, 0, missing, missing = 0);

        -- checksum of every weekly value; float sums are compared with a tolerance
        EXECUTE format(
            'SELECT (SELECT coalesce(sum(%s), 0) FROM %I.%I o),
                    (SELECT coalesce(sum(%s), 0) FROM vegetation.%I n
                     WHERE n.year = %s AND n.pixel_size = %s AND n.version = %s)',
            old_weeks, t.s, t.tb, new_weeks, lower(m[2]) || '_points', m[1], m[3], m[4])
        INTO n_old, n_new;
        INSERT INTO reconcile VALUES ('sum of weekly values', t.s || '.' || t.tb,
            round(n_old, 6), round(n_new, 6), abs(n_old - n_new) <= 1e-6 * greatest(1, abs(n_old)));
    END LOOP;

    ------------------------------------------------------------------
    -- media and analysis: row counts per year
    ------------------------------------------------------------------
    FOR t IN
        SELECT table_schema AS s, table_name AS tb,
               CASE WHEN table_name ~ '_mediadate$' THEN 'media' ELSE 'analysis_results' END AS target
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$'
          AND table_name ~ '^[0-9]{4}_(mediadate|list_of_.nalysis)$'
        ORDER BY 1, 2
    LOOP
        EXECUTE format(
            'SELECT (SELECT count(*) FROM %I.%I),
                    (SELECT count(*) FROM vegetation.%I WHERE year = %s)',
            t.s, t.tb, t.target, t.s)
        INTO n_old, n_new;
        INSERT INTO reconcile VALUES (t.target || ' rows', t.s || '.' || t.tb, n_old, n_new, n_old = n_new);
    END LOOP;
END
$$;

SELECT check_name, object, legacy, migrated, CASE WHEN ok THEN 'ok' ELSE 'MISMATCH' END AS status
FROM reconcile
ORDER BY ok, check_name, object;

DO $$
BEGIN
    IF EXISTS (SELECT FROM reconcile WHERE NOT ok) THEN
        RAISE EXCEPTION 'reconcile failed: % mismatches, see the table above',
            (SELECT count(*) FROM reconcile WHERE NOT ok);
    END IF;
END
$$;
