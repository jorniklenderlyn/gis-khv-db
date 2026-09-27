-- data-migration/02_dictionaries.sql
-- "Accounting".* (legacy) -> accounting.*, reclamation.reclamation_systems
-- Legacy ids are kept (OVERRIDING SYSTEM VALUE): fields reference them.
-- Identity sequences are synchronized later in 06_sequences.sql.
-- Run as superuser in the region database after 00_restore_legacy.sh:
--   docker compose exec -T -u postgres postgres psql -d <region> -f - < data-migration/02_dictionaries.sql

\set ON_ERROR_STOP on
\pset footer off

BEGIN;

-- refuse to run twice
DO $$
BEGIN
    IF EXISTS (SELECT FROM accounting.crops)
       OR EXISTS (SELECT FROM accounting.crop_varieties)
       OR EXISTS (SELECT FROM accounting.usage_types)
       OR EXISTS (SELECT FROM accounting.owners)
       OR EXISTS (SELECT FROM accounting.districts)
       OR EXISTS (SELECT FROM accounting.models)
       OR EXISTS (SELECT FROM reclamation.reclamation_systems)
    THEN
        RAISE EXCEPTION 'dictionaries are not empty, migration already done?';
    END IF;
END
$$;

INSERT INTO accounting.crops (id, name, color, note)
OVERRIDING SYSTEM VALUE
SELECT id, crop_name, crop_color, comment
FROM "Accounting".list_of_crops;

INSERT INTO accounting.crop_varieties (id, name, note, crop_id)
OVERRIDING SYSTEM VALUE
SELECT id, crop_sort_name, comment, id_crop
FROM "Accounting".list_of_crop_sorts;

INSERT INTO accounting.usage_types (id, name, note)
OVERRIDING SYSTEM VALUE
SELECT id, usage_type_name, comment
FROM "Accounting".list_of_usage_types;

INSERT INTO accounting.owners (id, name, note)
OVERRIDING SYSTEM VALUE
SELECT id, owner_name, comment
FROM "Accounting".list_of_owners;

INSERT INTO accounting.districts (id, name, note)
OVERRIDING SYSTEM VALUE
SELECT id, district_name, comment
FROM "Accounting".list_of_districts;

INSERT INTO accounting.models (id, name, note)
OVERRIDING SYSTEM VALUE
SELECT id, model_name, comment
FROM "Accounting".list_of_models;

-- reclamation systems exist only in khv
CREATE TEMP TABLE legacy_reclamation_count (cnt BIGINT NOT NULL);
INSERT INTO legacy_reclamation_count VALUES (0);

DO $$
DECLARE
    n BIGINT;
BEGIN
    IF to_regclass('"Accounting".list_of_reclamation_systems') IS NOT NULL THEN
        INSERT INTO reclamation.reclamation_systems (
            id, name, area, year_commissioned, year_reconstructed,
            wear_percent, water_receiver, water_source, geom
        )
        OVERRIDING SYSTEM VALUE
        SELECT
            id, name, area, year_commissioned, year_reconstructed,
            wear_percent, water_receiver, water_source, geom
        FROM "Accounting".list_of_reclamation_systems;

        -- the table may be absent, so it is counted here and not in the report query
        EXECUTE 'SELECT count(*) FROM "Accounting".list_of_reclamation_systems' INTO n;
        UPDATE legacy_reclamation_count SET cnt = n;
    END IF;
END
$$;

-- old vs new row counts
SELECT t.dictionary, t.old_rows, t.new_rows,
       CASE WHEN t.old_rows = t.new_rows THEN 'ok' ELSE 'MISMATCH' END AS status
FROM (
    SELECT 'crops' AS dictionary,
           (SELECT count(*) FROM "Accounting".list_of_crops) AS old_rows,
           (SELECT count(*) FROM accounting.crops) AS new_rows
    UNION ALL
    SELECT 'crop_varieties',
           (SELECT count(*) FROM "Accounting".list_of_crop_sorts),
           (SELECT count(*) FROM accounting.crop_varieties)
    UNION ALL
    SELECT 'usage_types',
           (SELECT count(*) FROM "Accounting".list_of_usage_types),
           (SELECT count(*) FROM accounting.usage_types)
    UNION ALL
    SELECT 'owners',
           (SELECT count(*) FROM "Accounting".list_of_owners),
           (SELECT count(*) FROM accounting.owners)
    UNION ALL
    SELECT 'districts',
           (SELECT count(*) FROM "Accounting".list_of_districts),
           (SELECT count(*) FROM accounting.districts)
    UNION ALL
    SELECT 'models',
           (SELECT count(*) FROM "Accounting".list_of_models),
           (SELECT count(*) FROM accounting.models)
    UNION ALL
    SELECT 'reclamation_systems',
           (SELECT cnt FROM legacy_reclamation_count),
           (SELECT count(*) FROM reclamation.reclamation_systems)
) AS t;

COMMIT;
