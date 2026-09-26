-- Deploy gis-storage:004_table_usage-types to pg

BEGIN;

CREATE TABLE accounting.usage_types (

    id INTEGER GENERATED ALWAYS AS IDENTITY,

    name VARCHAR NOT NULL,

    note VARCHAR,

    CONSTRAINT usage_types_pk
        PRIMARY KEY (id),

    CONSTRAINT usage_types_uq_name
        UNIQUE (name)
);

COMMIT;
