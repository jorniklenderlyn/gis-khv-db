-- data-migration/01_audit.sql
-- Read-only checks of legacy data restored by 00_restore_legacy.sh.
-- Run as superuser in the region database:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/01_audit.sql
--
-- severity:
--   blocker   - migration will fail on a constraint of the new schema
--   data_loss - legacy data has no place in the new schema
--   info      - migration works, but values will change or need attention

\set ON_ERROR_STOP on
\pset footer off

CREATE TEMP TABLE audit (
    severity TEXT,
    check_name TEXT,
    object TEXT,
    cnt BIGINT,
    detail TEXT
);

DO $$
DECLARE
    t RECORD;
    c RECORD;
    n BIGINT;
    y INTEGER;
    week_cols INTEGER;
BEGIN
    ------------------------------------------------------------------
    -- fields: YYYY.YYYY_list_of_fields
    ------------------------------------------------------------------
    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '^[0-9]{4}_list_of_fields$'
        ORDER BY 1
    LOOP
        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n;
        INSERT INTO audit VALUES ('info', 'rows', t.s || '.' || t.tb, n, NULL);

        -- columns the migration does not know about
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
              AND column_name !~ '^harves.?_date$'   -- "harvesе_date" has a Cyrillic "е"
        LOOP
            EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL', t.s, t.tb, c.col) INTO n;
            INSERT INTO audit VALUES (
                CASE WHEN n > 0 THEN 'data_loss' ELSE 'info' END,
                'unknown column', t.s || '.' || t.tb || '.' || c.col, n, 'non-null values'
            );
        END LOOP;

        -- PK (year, id): legacy tables may lack their primary key
        EXECUTE format(
            'SELECT count(*) FROM (SELECT id FROM %I.%I GROUP BY id HAVING count(*) > 1) d',
            t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('blocker', 'duplicate field id', t.s || '.' || t.tb, n,
                'fields_pk PRIMARY KEY (year, id) will fail');
        END IF;

        -- UNIQUE (year, hash): hash is recomputed by the new trigger
        EXECUTE format(
            'SELECT count(*) FROM (SELECT md5(ST_AsText(geom)) FROM %I.%I
             GROUP BY 1 HAVING count(*) > 1) d', t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('blocker', 'duplicate geometry in year', t.s || '.' || t.tb, n,
                'fields_hash_uq UNIQUE (year, hash) will fail');
        END IF;

        EXECUTE format('SELECT count(*) FROM %I.%I WHERE NOT ST_IsValid(geom)', t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('info', 'invalid geometry', t.s || '.' || t.tb, n,
                'area may be wrong');
        END IF;

        -- legacy area_insert used ST_Area on SRID 4326 (square degrees) before switching to UTM
        EXECUTE format(
            'SELECT count(*) FROM %I.%I WHERE area IS NOT NULL AND abs(area - ST_Area(geom)) < 1e-9',
            t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('info', 'area in square degrees', t.s || '.' || t.tb, n,
                'new area is recomputed in m2; legacy values are not comparable');
        END IF;

        EXECUTE format('SELECT count(*) FROM %I.%I WHERE hash_unique IS NULL', t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('info', 'hash was not computed', t.s || '.' || t.tb, n,
                'legacy table had no hash trigger; new trigger will compute it');
        END IF;
    END LOOP;

    ------------------------------------------------------------------
    -- points: YYYY.YYYY_NDVI_<size>_<version>, YYYY.YYYY_EVI_<size>_<version>
    ------------------------------------------------------------------
    FOR t IN
        SELECT table_schema AS s, table_name AS tb
        FROM information_schema.tables
        WHERE table_schema ~ '^[0-9]{4}$' AND table_name ~ '_(NDVI|EVI)'
        ORDER BY 1, 2
    LOOP
        EXECUTE format('SELECT count(*) FROM %I.%I', t.s, t.tb) INTO n;
        INSERT INTO audit VALUES ('info', 'rows', t.s || '.' || t.tb, n, NULL);

        IF t.tb !~ '^[0-9]{4}_(NDVI|EVI)_[0-9]+_[0-9]+$' THEN
            INSERT INTO audit VALUES ('blocker', 'unexpected table name', t.s || '.' || t.tb, NULL,
                'pixel_size and version are taken from the name YYYY_(NDVI|EVI)_<size>_<version>');
            CONTINUE;
        END IF;

        SELECT count(*) INTO week_cols
        FROM information_schema.columns
        WHERE table_schema = t.s AND table_name = t.tb AND column_name ~* '^(ndv|evi)[0-9]+$';
        IF week_cols <> 52 THEN
            INSERT INTO audit VALUES ('blocker', 'week columns', t.s || '.' || t.tb, week_cols,
                'expected 52 week columns');
        END IF;

        FOR c IN
            SELECT column_name AS col
            FROM information_schema.columns
            WHERE table_schema = t.s AND table_name = t.tb
              -- legacy tables differ in case: "X"/"NDV1" in some, x/ndv1 in others
              AND lower(column_name) NOT IN ('id', 'geom', 'x', 'y', 'id_crop_plan',
                                             'id_crop_pixel_result', 'id_field', 'comment')
              AND column_name !~* '^(ndv|evi)[0-9]+$'
        LOOP
            EXECUTE format('SELECT count(*) FROM %I.%I WHERE %I IS NOT NULL', t.s, t.tb, c.col) INTO n;
            INSERT INTO audit VALUES (
                CASE WHEN n > 0 THEN 'data_loss' ELSE 'info' END,
                'unknown column', t.s || '.' || t.tb || '.' || c.col, n, 'non-null values'
            );
        END LOOP;

        -- UNIQUE (year, pixel_size, version, x, y): legacy tables may lack UNIQUE ("X", "Y")
        EXECUTE format(
            'SELECT count(*) FROM (SELECT FROM %I.%I GROUP BY %s, %s HAVING count(*) > 1) d',
            t.s, t.tb,
            (SELECT quote_ident(column_name) FROM information_schema.columns
             WHERE table_schema = t.s AND table_name = t.tb AND lower(column_name) = 'x'),
            (SELECT quote_ident(column_name) FROM information_schema.columns
             WHERE table_schema = t.s AND table_name = t.tb AND lower(column_name) = 'y')
        ) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('blocker', 'duplicate point x, y', t.s || '.' || t.tb, n,
                'UNIQUE (year, pixel_size, version, x, y) will fail; groups of duplicates');
        END IF;

        -- composite FK (year, field_id) -> fields
        EXECUTE format(
            'SELECT count(*) FROM %I.%I p
             WHERE NOT EXISTS (SELECT FROM %I.%I f WHERE f.id = p.id_field)',
            t.s, t.tb, t.s, t.s || '_list_of_fields') INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('blocker', 'point without field', t.s || '.' || t.tb, n,
                'FK (year, field_id) will fail');
        END IF;

        -- FK crop_pixel_result_id -> crops
        EXECUTE format(
            'SELECT count(*) FROM %I.%I p
             WHERE p.id_crop_pixel_result IS NOT NULL
               AND NOT EXISTS (SELECT FROM "Accounting".list_of_crops c WHERE c.id = p.id_crop_pixel_result)',
            t.s, t.tb) INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('blocker', 'unknown crop_pixel_result', t.s || '.' || t.tb, n,
                'FK to accounting.crops will fail');
        END IF;

        -- crop_plan_id is recomputed from the field by the new trigger
        EXECUTE format(
            'SELECT count(*) FROM %I.%I p JOIN %I.%I f ON f.id = p.id_field
             WHERE p.id_crop_plan IS DISTINCT FROM f.id_crop_plan',
            t.s, t.tb, t.s, t.s || '_list_of_fields') INTO n;
        IF n > 0 THEN
            INSERT INTO audit VALUES ('info', 'crop_plan differs from field', t.s || '.' || t.tb, n,
                'new value will be taken from the field');
        END IF;

        -- partition for the year must exist before loading
        y := t.s::INTEGER;
        IF NOT EXISTS (
            SELECT FROM pg_inherits i
            JOIN pg_class p ON p.oid = i.inhrelid
            WHERE i.inhparent = CASE WHEN t.tb ~ '_NDVI_'
                                     THEN 'vegetation.ndvi_points'::regclass
                                     ELSE 'vegetation.evi_points'::regclass END
              -- the bound is printed as FOR VALUES IN ('2021') for smallint keys
              AND pg_get_expr(p.relpartbound, p.oid) ~ format('^FOR VALUES IN \(''?%s''?\)$', y)
        ) THEN
            INSERT INTO audit VALUES ('blocker', 'no partition for year', t.s || '.' || t.tb, NULL,
                'create partition for year ' || y || ' before loading points');
        END IF;
    END LOOP;

    ------------------------------------------------------------------
    -- dictionaries
    ------------------------------------------------------------------
    SELECT count(*) INTO n FROM "Accounting".list_of_districts WHERE btrim(district_name) = '';
    IF n > 0 THEN
        INSERT INTO audit VALUES ('blocker', 'empty district name', 'Accounting.list_of_districts', n,
            'districts_ck_name CHECK will fail');
    END IF;

    SELECT count(*) INTO n FROM "Accounting".list_of_models WHERE length(model_name) > 255;
    IF n > 0 THEN
        INSERT INTO audit VALUES ('blocker', 'model name > 255', 'Accounting.list_of_models', n,
            'models.name VARCHAR(255)');
    END IF;

    FOR t IN
        SELECT table_name AS tb
        FROM information_schema.tables
        WHERE table_schema = 'Accounting'
        ORDER BY 1
    LOOP
        EXECUTE format('SELECT count(*) FROM "Accounting".%I', t.tb) INTO n;
        INSERT INTO audit VALUES ('info', 'rows', 'Accounting.' || t.tb, n, NULL);
    END LOOP;
END
$$;

SELECT severity, check_name, object, cnt, detail
FROM audit
ORDER BY
    CASE severity WHEN 'blocker' THEN 1 WHEN 'data_loss' THEN 2 ELSE 3 END,
    check_name, object;

-- stop the pipeline (make migrate-data) when the migration would fail or lose data
DO $$
BEGIN
    IF EXISTS (SELECT FROM audit WHERE severity IN ('blocker', 'data_loss')) THEN
        RAISE EXCEPTION 'audit failed: % blocker/data_loss findings, see the table above',
            (SELECT count(*) FROM audit WHERE severity IN ('blocker', 'data_loss'));
    END IF;
END
$$;
