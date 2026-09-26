-- Deploy gis-storage:012_table_media to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE vegetation.media (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    year SMALLINT NOT NULL,
    field_id INTEGER NOT NULL,
    reference VARCHAR NOT NULL,
    geom public.geometry(POINT, 4326) NULL,
    filming_date DATE NULL,
    note VARCHAR NULL,

    CONSTRAINT mediadate_pk
        PRIMARY KEY (id),

    CONSTRAINT mediadate_reference_uq
        UNIQUE (year, reference),
    -- FK
    CONSTRAINT mediadate_field_fk
        FOREIGN KEY (year, field_id)
        REFERENCES vegetation.fields (year, id)
);

CREATE INDEX media_idx_year_field_id
    ON vegetation.media (year, field_id);

COMMIT;
