-- Deploy gis-storage:016_functions to pg

BEGIN;

-- средний NDVI по неделям (замена старых "YYYY".avg_ndvi_YY_20)
-- p_crop_name: название фактической культуры поля
-- p_field_ids: произвольная выборка полей, например ARRAY(SELECT id FROM vegetation.fields WHERE ...)
-- недели со средним 0 не возвращаются (0 = нет снимка)
CREATE FUNCTION vegetation.ndvi_weekly_avg(
    p_year INTEGER,
    p_crop_name TEXT DEFAULT NULL,
    p_field_ids INTEGER [] DEFAULT NULL,
    p_pixel_size INTEGER DEFAULT 20,
    p_version INTEGER DEFAULT 1
)
RETURNS TABLE (week INTEGER, average_ndvi DOUBLE PRECISION)
LANGUAGE sql
STABLE
AS $$
    SELECT
        w.week::INTEGER,
        avg(w.ndvi)
    FROM vegetation.ndvi_points AS p
    INNER JOIN vegetation.fields AS f
        ON f.year = p.year
        AND f.id = p.field_id
    LEFT JOIN accounting.crops AS c
        ON c.id = f.crop_fact_id
    CROSS JOIN LATERAL unnest(ARRAY[
            p.ndvi_week_01,
            p.ndvi_week_02,
            p.ndvi_week_03,
            p.ndvi_week_04,
            p.ndvi_week_05,
            p.ndvi_week_06,
            p.ndvi_week_07,
            p.ndvi_week_08,
            p.ndvi_week_09,
            p.ndvi_week_10,
            p.ndvi_week_11,
            p.ndvi_week_12,
            p.ndvi_week_13,
            p.ndvi_week_14,
            p.ndvi_week_15,
            p.ndvi_week_16,
            p.ndvi_week_17,
            p.ndvi_week_18,
            p.ndvi_week_19,
            p.ndvi_week_20,
            p.ndvi_week_21,
            p.ndvi_week_22,
            p.ndvi_week_23,
            p.ndvi_week_24,
            p.ndvi_week_25,
            p.ndvi_week_26,
            p.ndvi_week_27,
            p.ndvi_week_28,
            p.ndvi_week_29,
            p.ndvi_week_30,
            p.ndvi_week_31,
            p.ndvi_week_32,
            p.ndvi_week_33,
            p.ndvi_week_34,
            p.ndvi_week_35,
            p.ndvi_week_36,
            p.ndvi_week_37,
            p.ndvi_week_38,
            p.ndvi_week_39,
            p.ndvi_week_40,
            p.ndvi_week_41,
            p.ndvi_week_42,
            p.ndvi_week_43,
            p.ndvi_week_44,
            p.ndvi_week_45,
            p.ndvi_week_46,
            p.ndvi_week_47,
            p.ndvi_week_48,
            p.ndvi_week_49,
            p.ndvi_week_50,
            p.ndvi_week_51,
            p.ndvi_week_52
    ]) WITH ORDINALITY AS w (ndvi, week)
    WHERE p.year = p_year
      AND p.pixel_size = p_pixel_size
      AND p.version = p_version
      AND (p_crop_name IS NULL OR c.name = p_crop_name)
      AND (p_field_ids IS NULL OR p.field_id = ANY (p_field_ids))
    GROUP BY w.week
    HAVING avg(w.ndvi) <> 0
    ORDER BY w.week;
$$;

COMMIT;
