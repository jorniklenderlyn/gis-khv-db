-- Deploy gis-storage:005_accounting_owner to pg

BEGIN;

CREATE TABLE accounting.owners (

    id integer GENERATED ALWAYS AS IDENTITY,

    name varchar NOT NULL,

    note varchar NULL,

    CONSTRAINT owners_pk
        PRIMARY KEY (id),

    CONSTRAINT owners_uq_name
        UNIQUE (name)

);

COMMIT;
