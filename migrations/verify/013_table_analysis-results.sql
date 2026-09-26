-- Verify gis-storage:012_table_analysis-results on pg

BEGIN;

SELECT id, field_id, model_id, results, note
FROM vegetation.analysis_results
WHERE FALSE;

ROLLBACK;
