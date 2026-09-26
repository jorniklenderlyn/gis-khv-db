-- Revert gis-storage:012_table_analysis-results from pg

BEGIN;

DROP TABLE vegetation.analysis_results;

COMMIT;
