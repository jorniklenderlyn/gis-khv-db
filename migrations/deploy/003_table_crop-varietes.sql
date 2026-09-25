-- Deploy gis-storage:003_table_crop-varietes to pg

BEGIN;

CREATE TABLE accounting.crop_varieties (

    id integer GENERATED ALWAYS AS IDENTITY,

    name varchar NOT NULL,

    note varchar NULL,

    crop_id integer NOT NULL,

    CONSTRAINT crop_varieties_pk
        PRIMARY KEY (id),

    CONSTRAINT crop_varieties_uq_name_crop
        UNIQUE (name, crop_id),

    CONSTRAINT crop_varieties_fk_crop
        FOREIGN KEY (crop_id)
        REFERENCES accounting.crops (id)

);

COMMIT;
