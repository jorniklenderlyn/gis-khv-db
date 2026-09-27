-- data-migration/03_fields.sql
-- "YYYY"."YYYY_list_of_fields" (legacy, one table per year) -> vegetation.fields
-- Legacy ids are kept (OVERRIDING SYSTEM VALUE); PK is (year, id), so the same id
-- in different years is allowed. area and hash are recomputed by the triggers
-- (fields_trg_area, fields_trg_hash), legacy values are not copied.
-- Run as superuser in the region database after 02_dictionaries.sql:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/03_fields.sql

\set ON_ERROR_STOP on
\pset footer off

BEGIN;

CREATE TEMP TABLE fields_report (year INTEGER, old_rows BIGINT, new_rows BIGINT);

DO $$
DECLARE
    t RECORD;
    c RECORD;
    y INTEGER;
    harvest_col TEXT;
    reclamation_col TEXT;
    unknown TEXT;
    n BIGINT;
BEGIN
    IF EXISTS (SELECT FROM vegetation.fields) THEN
        RAISE EXCEPTION 'vegetation.fields is not empty, migration already done?';
    END IF;

    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_list_of_fields$'
        ORDER BY 1
    LOOP
        y := t.s::INTEGER;

        -- legacy columns with data that have no place in the new schema
        -- (e.g. khv 2021: intern_number_dvniis, id_distric); decide before migrating.
        -- Empty unknown columns are skipped.
        unknown := NULL;
        FOR c IN
            SELECT column_name AS col
            FROM information_schema.columns
            WHERE table_schema = t.s AND table_name = t.tb
              AND column_name NOT IN (
                  'id', 'geom', 'reestr_number', 'comment', 'intern_number',
                  'id_district', 'id_owner', 'area', 'id_type_usage_plan',
                  'id_type_usage_fact', 'id_crop_plan', 'id_crop_fact',
                  'id_crop_sort_plan', 'id_crop_sort_fact', 'biochem_fact',
                  'harvest_fact', 'harvest_forecast', 'pesticides', 'fertilizers',
                  'sowing_date', 'inspected', 'hash_unique', 'id_reclamation_system'
              )
              AND column_name !~ '^harves.?_date$'
        LOOP
            EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL', t.s, t.tb, c.col) INTO n;
            IF n > 0 THEN
                unknown := concat_ws(', ', unknown, format('%s (%s rows)', c.col, n));
            END IF;
        END LOOP;
        IF unknown IS NOT NULL THEN
            RAISE EXCEPTION '%.%: unknown columns (%), decide where to migrate them',
                t.s, t.tb, unknown;
        END IF;

        -- "harvesе_date" has a Cyrillic "е"; take the real name from the catalog
        SELECT quote_ident(column_name) INTO harvest_col
        FROM information_schema.columns
        WHERE table_schema = t.s AND table_name = t.tb AND column_name ~ '^harves.?_date$';

        -- id_reclamation_system exists only in khv
        SELECT quote_ident(column_name) INTO reclamation_col
        FROM information_schema.columns
        WHERE table_schema = t.s AND table_name = t.tb AND column_name = 'id_reclamation_system';

        EXECUTE format(
            'INSERT INTO vegetation.fields (
                id, year, geom, registr_number, note, intern_number,
                district_id, owner_id, type_usage_plan_id, type_usage_fact_id,
                crop_plan_id, crop_fact_id, crop_variety_plan_id, crop_variety_fact_id,
                biochem_fact, harvest_fact, harvest_forecast, pesticides, fertilizers,
                sowing_date, harvest_date, inspected, reclamation_system_id
            )
            OVERRIDING SYSTEM VALUE
            SELECT
                id, %s, geom, reestr_number, comment, intern_number,
                id_district, id_owner, id_type_usage_plan, id_type_usage_fact,
                id_crop_plan, id_crop_fact, id_crop_sort_plan, id_crop_sort_fact,
                biochem_fact, harvest_fact, harvest_forecast, pesticides, fertilizers,
                sowing_date, %s, inspected, %s
            FROM %I.%I',
            y,
            coalesce(harvest_col, 'NULL'),
            coalesce(reclamation_col, 'NULL'),
            t.s, t.tb
        );

        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n;
        INSERT INTO fields_report
        SELECT y, n, count(*) FROM vegetation.fields WHERE year = y;
    END LOOP;
END
$$;

SELECT year, old_rows, new_rows,
       CASE WHEN old_rows = new_rows THEN 'ok' ELSE 'MISMATCH' END AS status
FROM fields_report
ORDER BY year;

COMMIT;
