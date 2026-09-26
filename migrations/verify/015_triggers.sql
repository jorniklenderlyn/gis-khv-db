-- Verify gis-storage:015_triggers on pg

BEGIN;

-- ::regprocedure падает, если функции нет
SELECT 'vegetation.set_area()'::regprocedure;
SELECT 'vegetation.set_hash()'::regprocedure;
SELECT 'vegetation.set_point_geom()'::regprocedure;
SELECT 'vegetation.set_crop_plan()'::regprocedure;

-- 1 / count(*) падает делением на ноль, если триггера нет
SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.fields'::regclass AND tgname = 'fields_trg_area';

SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.fields'::regclass AND tgname = 'fields_trg_hash';

SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.ndvi_points'::regclass AND tgname = 'ndvi_points_trg_geom';

SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.ndvi_points'::regclass AND tgname = 'ndvi_points_trg_crop_plan';

SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.evi_points'::regclass AND tgname = 'evi_points_trg_geom';

SELECT 1 / count(*) FROM pg_trigger
WHERE tgrelid = 'vegetation.evi_points'::regclass AND tgname = 'evi_points_trg_crop_plan';

ROLLBACK;
