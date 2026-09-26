-- Deploy gis-storage:007_table_models to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE accounting.models (
    id         INTEGER      GENERATED ALWAYS AS IDENTITY,
    name       VARCHAR(255) NOT NULL,
    note       VARCHAR      NULL,
    CONSTRAINT models_pk PRIMARY KEY (id),
    CONSTRAINT models_uq_name UNIQUE (name)
);

COMMIT;
