-- Deploy gis-storage:004_table_usage-types to pg

BEGIN;

CREATE TABLE accounting.usage_types (

    id integer GENERATED ALWAYS AS IDENTITY,

    name varchar NOT NULL,

    note varchar,

    CONSTRAINT usage_types_pk
        PRIMARY KEY (id),

    CONSTRAINT usage_types_uq_name
        UNIQUE (name)
);

COMMIT;
