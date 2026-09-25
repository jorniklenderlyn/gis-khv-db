-- Deploy gis-storage:007_table_models to pg

BEGIN;

CREATE TABLE accounting.models (
    id         integer      GENERATED ALWAYS AS IDENTITY,
    name       varchar(255) NOT NULL,
    note       varchar      NULL,
    CONSTRAINT models_pk PRIMARY KEY (id),
    CONSTRAINT models_uq_name UNIQUE (name)
);

COMMIT;
