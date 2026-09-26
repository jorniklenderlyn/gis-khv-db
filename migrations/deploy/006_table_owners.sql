-- Deploy gis-storage:005_accounting_owner to pg

BEGIN;

CREATE TABLE accounting.owners (

    id INTEGER GENERATED ALWAYS AS IDENTITY,

    name VARCHAR NOT NULL,

    note VARCHAR NULL,

    CONSTRAINT owners_pk
        PRIMARY KEY (id),

    CONSTRAINT owners_uq_name
        UNIQUE (name)

);

COMMIT;
