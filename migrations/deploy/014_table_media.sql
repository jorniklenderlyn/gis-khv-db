-- Deploy gis-storage:012_table_media to pg

BEGIN;

CREATE TABLE vegetation.media (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    field_id INTEGER NOT NULL,
    reference VARCHAR NOT NULL,
    geom public.geometry(POINT, 4326) NULL,
    filming_date DATE NULL,
    note VARCHAR NULL,

    CONSTRAINT mediadate_pk
        PRIMARY KEY (id),

    CONSTRAINT mediadate_reference_uq
        UNIQUE (reference),
    -- FK
    CONSTRAINT mediadate_field_fk
        FOREIGN KEY (field_id)
        REFERENCES vegetation.fields (id)
);

COMMIT;
