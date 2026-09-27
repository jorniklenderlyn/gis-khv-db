-- data-migration/04_points.sql
-- "YYYY"."YYYY_NDVI_<size>_<version>" -> vegetation.ndvi_points
-- "YYYY"."YYYY_EVI_<size>_<version>"  -> vegetation.evi_points
-- pixel_size and version are taken from the table name.
-- Points get new ids: nothing references point ids, and legacy tables are not
-- guaranteed to have unique ids (a 2024 amr snapshot had 100k repeated ids).
-- A point is identified by (year, pixel_size, version, x, y).
-- geom and crop_plan_id are filled by the triggers (*_trg_geom, *_trg_crop_plan).
-- Rows go through the parent table: on PG13 a direct insert into a partition
-- does not get identity values.
-- Partitions for every year must exist (01_audit.sql reports missing ones).
-- Run as superuser in the region database after 03_fields.sql:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/04_points.sql

\set ON_ERROR_STOP on
\pset footer off

BEGIN;

CREATE TEMP TABLE points_report (
    legacy_table TEXT, target TEXT, year INTEGER, pixel_size INTEGER, version INTEGER,
    old_rows BIGINT, new_rows BIGINT
);

DO $$
DECLARE
    t RECORD;
    m TEXT[];
    y INTEGER;
    size INTEGER;
    ver INTEGER;
    target TEXT;
    week_prefix TEXT;
    src_weeks TEXT;
    dst_weeks TEXT;
    col_x TEXT;
    col_y TEXT;
    col_field TEXT;
    col_pixel TEXT;
    col_comment TEXT;
    n_old BIGINT;
    n_new BIGINT;
BEGIN
    IF EXISTS (SELECT FROM vegetation.ndvi_points) OR EXISTS (SELECT FROM vegetation.evi_points) THEN
        RAISE EXCEPTION 'ndvi_points/evi_points are not empty, migration already done?';
    END IF;

    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '_(NDVI|EVI)'
        ORDER BY 1, 2
    LOOP
        m := regexp_match(t.tb, '^([0-9]{4})_(NDVI|EVI)_([0-9]+)_([0-9]+)$');
        IF m IS NULL THEN
            RAISE EXCEPTION '%.%: unexpected table name, expected YYYY_(NDVI|EVI)_<size>_<version>',
                t.s, t.tb;
        END IF;

        y := t.s::INTEGER;
        size := m[3]::INTEGER;
        ver := m[4]::INTEGER;
        target := CASE m[2] WHEN 'NDVI' THEN 'ndvi_points' ELSE 'evi_points' END;
        week_prefix := CASE m[2] WHEN 'NDVI' THEN 'ndv' ELSE 'evi' END;

        -- legacy tables differ in case ("X"/"NDV1" or x/ndv1): resolve real names
        SELECT
            string_agg(quote_ident(c.column_name), ', ' ORDER BY w.i),
            string_agg(format('%s_week_%s', lower(m[2]), lpad(w.i::TEXT, 2, '0')), ', ' ORDER BY w.i)
        INTO src_weeks, dst_weeks
        FROM generate_series(1, 52) AS w (i)
        JOIN information_schema.columns AS c
            ON c.table_schema = t.s AND c.table_name = t.tb
           AND lower(c.column_name) = week_prefix || w.i;

        IF array_length(string_to_array(src_weeks, ', '), 1) IS DISTINCT FROM 52 THEN
            RAISE EXCEPTION '%.%: expected 52 week columns', t.s, t.tb;
        END IF;

        SELECT
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'x'),
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'y'),
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'id_field'),
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'id_crop_pixel_result'),
            max(quote_ident(column_name)) FILTER (WHERE lower(column_name) = 'comment')
        INTO col_x, col_y, col_field, col_pixel, col_comment
        FROM information_schema.columns
        WHERE table_schema = t.s AND table_name = t.tb;

        IF col_x IS NULL OR col_y IS NULL OR col_field IS NULL THEN
            RAISE EXCEPTION '%.%: x, y or id_field column not found', t.s, t.tb;
        END IF;

        EXECUTE format(
            'INSERT INTO vegetation.%I (
                year, pixel_size, version, x, y, %s,
                crop_pixel_result_id, field_id, note
            )
            SELECT %s, %s, %s, %s, %s, %s, %s, %s, %s
            FROM %I.%I',
            target, dst_weeks,
            y, size, ver, col_x, col_y, src_weeks,
            coalesce(col_pixel, 'NULL'), col_field, coalesce(col_comment, 'NULL'),
            t.s, t.tb
        );

        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n_old;
        EXECUTE format(
            'SELECT count(*) FROM vegetation.%I WHERE year = %s AND pixel_size = %s AND version = %s',
            target, y, size, ver) INTO n_new;
        INSERT INTO points_report VALUES (t.s || '.' || t.tb, target, y, size, ver, n_old, n_new);
    END LOOP;
END
$$;

SELECT legacy_table, target, year, pixel_size, version, old_rows, new_rows,
       CASE WHEN old_rows = new_rows THEN 'ok' ELSE 'MISMATCH' END AS status
FROM points_report
ORDER BY year, target, pixel_size, version;

COMMIT;
