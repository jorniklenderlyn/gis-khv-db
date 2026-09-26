-- Deploy gis-storage:003_table_crop-varietes to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE accounting.crop_varieties (

    id INTEGER GENERATED ALWAYS AS IDENTITY,

    name VARCHAR NOT NULL,

    note VARCHAR NULL,

    crop_id INTEGER NOT NULL,

    CONSTRAINT crop_varieties_pk
        PRIMARY KEY (id),

    CONSTRAINT crop_varieties_uq_name_crop
        UNIQUE (name, crop_id),

    CONSTRAINT crop_varieties_fk_crop_id
        FOREIGN KEY (crop_id)
        REFERENCES accounting.crops (id)

);

COMMIT;
