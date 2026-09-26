-- Deploy gis-storage:013_table_reclamation-systems to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE reclamation.reclamation_systems (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    name VARCHAR NOT NULL,
    area DOUBLE PRECISION,
    year_commissioned INTEGER,
    year_reconstructed INTEGER,
    wear_percent DOUBLE PRECISION,
    water_receiver VARCHAR,
    water_source VARCHAR,
    geom public.geometry(MULTIPOLYGON, 4326),

    CONSTRAINT reclamation_systems_pk
        PRIMARY KEY (id)
);

COMMIT;
