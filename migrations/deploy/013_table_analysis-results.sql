-- Deploy gis-storage:011_table_analysis-results to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE vegetation.analysis_results (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    year SMALLINT NOT NULL,
    field_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    results VARCHAR NOT NULL,
    note VARCHAR NULL,

    CONSTRAINT analysis_results_pk
        PRIMARY KEY (year, id),

    CONSTRAINT analysis_results_uq_field_id_model_id
        UNIQUE (year, field_id, model_id),

    -- FK
    CONSTRAINT analysis_results_fk_field_id
        FOREIGN KEY (year, field_id)
        REFERENCES vegetation.fields (year, id),

    CONSTRAINT analysis_results_fk_model_id
        FOREIGN KEY (model_id)
        REFERENCES accounting.models (id)
)
-- партиции по годам создаются по факту появления данных за год,
-- см. docs/README.md#partitioning
PARTITION BY LIST (year);

COMMIT;
