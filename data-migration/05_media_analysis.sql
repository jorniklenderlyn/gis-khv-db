-- data-migration/05_media_analysis.sql
-- "YYYY"."YYYY_mediadate"        -> vegetation.media
-- "YYYY"."YYYY_list_of_аnalysis" -> vegetation.analysis_results  (Cyrillic "а" in the legacy name)
-- Rows get new ids: nothing references them, and legacy ids repeat across years
-- while PK of both tables is (id).
-- Run as superuser in the region database after 03_fields.sql:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/05_media_analysis.sql

\set ON_ERROR_STOP on
\pset footer off

BEGIN;

CREATE TEMP TABLE media_analysis_report (
    legacy_table TEXT, target TEXT, year INTEGER, old_rows BIGINT, new_rows BIGINT
);

DO $$
DECLARE
    t RECORD;
    y INTEGER;
    n_old BIGINT;
    n_new BIGINT;
BEGIN
    IF EXISTS (SELECT FROM vegetation.media) OR EXISTS (SELECT FROM vegetation.analysis_results) THEN
        RAISE EXCEPTION 'media/analysis_results are not empty, migration already done?';
    END IF;

    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_mediadate$'
        ORDER BY 1
    LOOP
        y := t.s::INTEGER;
        EXECUTE format(
            'INSERT INTO vegetation.media (year, field_id, reference, geom, filming_date, note)
             SELECT %s, id_field, reference, geoteg, filming_date, comment
             FROM %I.%I',
            y, t.s, t.tb);

        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n_old;
        SELECT count(*) INTO n_new FROM vegetation.media WHERE year = y;
        INSERT INTO media_analysis_report VALUES (t.s || '.' || t.tb, 'media', y, n_old, n_new);
    END LOOP;

    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_list_of_.nalysis$'
        ORDER BY 1
    LOOP
        y := t.s::INTEGER;
        EXECUTE format(
            'INSERT INTO vegetation.analysis_results (year, field_id, model_id, results, note)
             SELECT %s, id_field, id_model, results, comment
             FROM %I.%I',
            y, t.s, t.tb);

        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n_old;
        SELECT count(*) INTO n_new FROM vegetation.analysis_results WHERE year = y;
        INSERT INTO media_analysis_report VALUES (t.s || '.' || t.tb, 'analysis_results', y, n_old, n_new);
    END LOOP;
END
$$;

SELECT legacy_table, target, year, old_rows, new_rows,
       CASE WHEN old_rows = new_rows THEN 'ok' ELSE 'MISMATCH' END AS status
FROM media_analysis_report
ORDER BY target, year;

COMMIT;
