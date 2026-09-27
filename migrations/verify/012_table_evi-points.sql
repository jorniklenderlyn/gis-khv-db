-- Verify gis-storage:010_table_evi-points on pg

BEGIN;

SELECT id, year, pixel_size, version, geom, x, y, field_id, note
FROM vegetation.evi_points
WHERE FALSE;

-- секционирование по годам (LIST (year)); вложенные уровни
-- pixel_size и version задаются при создании партиций, а не здесь
SELECT 1 / count(*)
FROM pg_class AS c
WHERE c.oid = 'vegetation.evi_points'::regclass
  AND c.relkind = 'p'
  AND pg_get_partkeydef(c.oid) = 'LIST (year)';

ROLLBACK;
