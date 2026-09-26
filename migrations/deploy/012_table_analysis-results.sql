-- Deploy gis-storage:011_table_analysis-results to pg

BEGIN;

CREATE TABLE vegetation.analysis_results (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    field_id INTEGER NOT NULL,
    model_id INTEGER NOT NULL,
    results VARCHAR NOT NULL,
    note VARCHAR NULL,

    CONSTRAINT analysis_results_pk
        PRIMARY KEY (id),

    CONSTRAINT analysis_results_uq_field_id_model_id
        UNIQUE (id_field, id_model)
    -- FK
    CONSTRAINT analysis_results_fk_field_id
        FOREIGN KEY (field_id)
        REFERENCES vegetation.fields (id)

    CONSTRAINT analysis_results_fk_model_id
        FOREIGN KEY (field_id)
        REFERENCES accounting.models (id)
);

COMMIT;
