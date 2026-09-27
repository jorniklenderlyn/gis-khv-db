-- Verify gis-storage:012_table_analysis-results on pg

BEGIN;

SELECT id, year, field_id, model_id, results, note
FROM vegetation.analysis_results
WHERE FALSE;

-- секционирование по годам (LIST (year)); 1 / count(*) падает делением на ноль
SELECT 1 / count(*)
FROM pg_class AS c
WHERE c.oid = 'vegetation.analysis_results'::regclass
  AND c.relkind = 'p'
  AND pg_get_partkeydef(c.oid) = 'LIST (year)';

ROLLBACK;
