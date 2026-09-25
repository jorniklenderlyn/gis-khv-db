-- Deploy gis-storage:006_table_districts to pg

BEGIN;

CREATE TABLE accounting.districts (
    id         integer     GENERATED ALWAYS AS IDENTITY,
    name       varchar     NOT NULL,
    note       varchar     NULL,
    CONSTRAINT districts_pk PRIMARY KEY (id),
    CONSTRAINT districts_uq_name UNIQUE (name),
    CONSTRAINT districts_ck_name CHECK (btrim(name) <> '')
);

COMMIT;
