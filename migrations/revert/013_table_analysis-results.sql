-- Revert gis-storage:012_table_analysis-results from pg

BEGIN;

SET LOCAL ROLE gis_owner;

DROP TABLE vegetation.analysis_results;

COMMIT;
