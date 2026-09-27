-- Verify gis-storage:009_table_ndvi-points on pg

BEGIN;

SELECT id, year, pixel_size, version, geom, x, y, field_id, note
FROM vegetation.ndvi_points
WHERE FALSE;

-- секционирование по годам (LIST (year)); вложенные уровни
-- pixel_size и version задаются при создании партиций, а не здесь
SELECT 1 / count(*)
FROM pg_class AS c
WHERE c.oid = 'vegetation.ndvi_points'::regclass
  AND c.relkind = 'p'
  AND pg_get_partkeydef(c.oid) = 'LIST (year)';

ROLLBACK;
