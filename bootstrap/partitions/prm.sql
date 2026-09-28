-- Partitions for region: khv
--
--   make partitions REGION=khv
--
-- Re-running is safe: every statement is CREATE TABLE IF NOT EXISTS, so what
-- already exists is skipped. Adding a year / pixel size / version means
-- editing the block for that table below and running the target again.
--
-- The sets mirror the legacy per-year schemas, one table per
-- <year>_<index>_<pixel_size>_<version>. NDVI and EVI do not hold the same
-- pixel sizes, so their subtrees differ:
--
--   ndvi_points  10 -> v1;  20 -> v1, v2;  30 -> v1, v2;  60 -> v1, v2
--   evi_points   20 -> v1
--
-- Only 2019 was read from the legacy database; the same sets are applied to
-- every other year. Check each year against the legacy schema and remove what
-- does not apply -- an extra empty partition is harmless and can be dropped,
-- but a wrong set here is a silent mismatch with the source data.
--
-- This file describes what THIS region holds. Other regions legitimately hold
-- a different set, which is why partitions are not part of the migrations --
-- see docs/README.md#partitions-are-not-part-of-migrations.
--
-- Naming: <table>_<year>_p<pixel_size>_v<version>, see
-- docs/README.md#naming-convention.

\set ON_ERROR_STOP on

BEGIN;

-- Partitions must be owned by gis_owner, exactly like migration objects, so
-- that the ALTER DEFAULT PRIVILEGES from 017_privileges grants gis_app /
-- gis_edit / gis_read automatically. No per-partition GRANT is needed.
SET LOCAL ROLE gis_owner;

-- ---------------------------------------------------------------------
-- vegetation.fields: one partition per year
--
-- One loop per table, so each table's year list can diverge from the
-- others without touching them.
-- ---------------------------------------------------------------------

DO $$
DECLARE
    -- Years this region holds fields data for.
    v_years CONSTANT integer [] := ARRAY[
        2022, 2023, 2024, 2025
    ];

    v_year integer;
BEGIN
    FOREACH v_year IN ARRAY v_years LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS vegetation.%I '
            'PARTITION OF vegetation.fields FOR VALUES IN (%s)',
            'fields_' || v_year, v_year);
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- vegetation.analysis_results: one partition per year
--
-- Analysis results are written per year; this list need not match fields.
-- ---------------------------------------------------------------------

DO $$
DECLARE
    -- Years this region holds analysis_results data for.
    v_years CONSTANT integer [] := ARRAY[
        2022, 2023, 2024, 2025
    ];

    v_year integer;
BEGIN
    FOREACH v_year IN ARRAY v_years LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS vegetation.%I '
            'PARTITION OF vegetation.analysis_results FOR VALUES IN (%s)',
            'analysis_results_' || v_year, v_year);
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- vegetation.media: one partition per year
--
-- Media references are per year; this list need not match fields.
-- ---------------------------------------------------------------------

DO $$
DECLARE
    -- Years this region holds media data for.
    v_years CONSTANT integer [] := ARRAY[
        2022, 2023, 2024, 2025
    ];

    v_year integer;
BEGIN
    FOREACH v_year IN ARRAY v_years LOOP
        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS vegetation.%I '
            'PARTITION OF vegetation.media FOR VALUES IN (%s)',
            'media_' || v_year, v_year);
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- vegetation.ndvi_points: year -> pixel_size -> version
--
-- Same suite every year, so it is a loop rather than 63 near-identical
-- statements.
-- The two declarations below are the whole description of what this region
-- holds for NDVI.
-- ---------------------------------------------------------------------

DO $$
DECLARE
    -- Years this region holds NDVI data for.
    v_years CONSTANT integer [] := ARRAY[
        2022, 2023, 2024, 2025
    ];

    v_year integer;
    v_version integer;
    v_pixel record;
    v_year_part text;
    v_pixel_part text;
BEGIN
    FOREACH v_year IN ARRAY v_years LOOP
        v_year_part := 'ndvi_points_' || v_year;

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS vegetation.%I '
            'PARTITION OF vegetation.ndvi_points '
            'FOR VALUES IN (%s) PARTITION BY LIST (pixel_size)',
            v_year_part, v_year);

        -- Pixel sizes, and the versions held for each of them.
        FOR v_pixel IN
            SELECT
                s.pixel_size,
                s.versions
            FROM (VALUES
                    (10, ARRAY[1]),
                    (20, ARRAY[1, 2]),
                    (30, ARRAY[1, 2]),
                    (60, ARRAY[1, 2])
            ) AS s (pixel_size, versions)
            ORDER BY s.pixel_size
        LOOP
            v_pixel_part := v_year_part || '_p' || v_pixel.pixel_size;

            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS vegetation.%I '
                'PARTITION OF vegetation.%I '
                'FOR VALUES IN (%s) PARTITION BY LIST (version)',
                v_pixel_part, v_year_part, v_pixel.pixel_size);

            FOREACH v_version IN ARRAY v_pixel.versions LOOP
                EXECUTE format(
                    'CREATE TABLE IF NOT EXISTS vegetation.%I '
                    'PARTITION OF vegetation.%I FOR VALUES IN (%s)',
                    v_pixel_part || '_v' || v_version,
                    v_pixel_part, v_version);
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

-- ---------------------------------------------------------------------
-- vegetation.evi_points: year -> pixel_size -> version
--
-- A separate loop from ndvi_points: EVI holds a different set of pixel
-- sizes, and its years may diverge independently.
-- The two declarations below are the whole description of what this region
-- holds for EVI.
-- ---------------------------------------------------------------------

DO $$
DECLARE
    -- Years this region holds EVI data for.
    v_years CONSTANT integer [] := ARRAY[
        2022, 2023, 2024, 2025
    ];

    v_year integer;
    v_version integer;
    v_pixel record;
    v_year_part text;
    v_pixel_part text;
BEGIN
    FOREACH v_year IN ARRAY v_years LOOP
        v_year_part := 'evi_points_' || v_year;

        EXECUTE format(
            'CREATE TABLE IF NOT EXISTS vegetation.%I '
            'PARTITION OF vegetation.evi_points '
            'FOR VALUES IN (%s) PARTITION BY LIST (pixel_size)',
            v_year_part, v_year);

        -- Pixel sizes, and the versions held for each of them.
        FOR v_pixel IN
            SELECT
                s.pixel_size,
                s.versions
            FROM (VALUES
                    (20, ARRAY[1])
            ) AS s (pixel_size, versions)
            ORDER BY s.pixel_size
        LOOP
            v_pixel_part := v_year_part || '_p' || v_pixel.pixel_size;

            EXECUTE format(
                'CREATE TABLE IF NOT EXISTS vegetation.%I '
                'PARTITION OF vegetation.%I '
                'FOR VALUES IN (%s) PARTITION BY LIST (version)',
                v_pixel_part, v_year_part, v_pixel.pixel_size);

            FOREACH v_version IN ARRAY v_pixel.versions LOOP
                EXECUTE format(
                    'CREATE TABLE IF NOT EXISTS vegetation.%I '
                    'PARTITION OF vegetation.%I FOR VALUES IN (%s)',
                    v_pixel_part || '_v' || v_version,
                    v_pixel_part, v_version);
            END LOOP;
        END LOOP;
    END LOOP;
END;
$$;

COMMIT;

-- What the region now has.
SELECT
    c.oid::regclass::text AS partition_name,
    pg_get_expr(c.relpartbound, c.oid) AS bounds,
    pg_get_partkeydef(c.oid) AS subpartitioned_by,
    pg_get_userbyid(c.relowner) AS owner_role
FROM pg_class AS c
INNER JOIN pg_namespace AS n ON c.relnamespace = n.oid
WHERE
    c.relispartition
    AND c.relkind IN ('r', 'p')
    AND n.nspname = 'vegetation'
ORDER BY 1;

-- Fails with a division by zero if any partition is not owned by gis_owner.
-- That is the one silent failure of creating partitions outside a migration:
-- a partition created by another role does not pick up the ALTER DEFAULT
-- PRIVILEGES from 017_privileges, so gis_app / gis_edit / gis_read receive
-- nothing on it and nobody notices until a query hits that one year.
SELECT 1 / (count(*) = 0)::int AS all_partitions_owned_by_gis_owner
FROM pg_class AS c
INNER JOIN pg_namespace AS n ON c.relnamespace = n.oid
WHERE
    c.relispartition
    AND c.relkind IN ('r', 'p')
    AND n.nspname IN ('accounting', 'vegetation', 'reclamation')
    AND c.relowner <> 'gis_owner'::regrole;
