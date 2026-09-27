-- Verify gis-storage:013_table_media on pg

BEGIN;

SELECT id, year, field_id, reference, geom, filming_date, note
FROM vegetation.media
WHERE FALSE;

-- секционирование по годам (LIST (year)); 1 / count(*) падает делением на ноль
SELECT 1 / count(*)
FROM pg_class AS c
WHERE c.oid = 'vegetation.media'::regclass
  AND c.relkind = 'p'
  AND pg_get_partkeydef(c.oid) = 'LIST (year)';

ROLLBACK;
