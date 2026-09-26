-- Deploy gis-storage:010_table_fields to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE vegetation.fields (
    id INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    year SMALLINT NOT NULL,
    geom public.geometry(MULTIPOLYGON, 4326) NOT NULL,
    registr_number VARCHAR NULL,
    note VARCHAR NULL,
    intern_number VARCHAR NULL,
    district_id INTEGER NULL,
    owner_id INTEGER NULL,
    area FLOAT8 NULL,
    type_usage_plan_id INTEGER NULL,
    type_usage_fact_id INTEGER NULL,
    crop_plan_id INTEGER NULL,
    crop_fact_id INTEGER NULL,
    crop_variety_plan_id INTEGER NULL,
    crop_variety_fact_id INTEGER NULL,
    biochem_fact VARCHAR NULL,
    harvest_fact FLOAT4 NULL,
    harvest_forecast FLOAT4 NULL,
    pesticides VARCHAR NULL,
    fertilizers VARCHAR NULL,
    sowing_date DATE NULL,
    harvest_date DATE NULL,
    inspected BOOLEAN NOT NULL DEFAULT FALSE,
    hash TEXT,
    reclamation_system_id INTEGER,

    CONSTRAINT fields_pk
        PRIMARY KEY (year, id),

    CONSTRAINT fields_hash_uq
        UNIQUE (year, hash),

    -- FK
    CONSTRAINT fields_fk_district_id
        FOREIGN KEY (district_id)
        REFERENCES accounting.districts (id),

    CONSTRAINT fields_fk_owner_id
        FOREIGN KEY (owner_id)
        REFERENCES accounting.owners (id),

    CONSTRAINT fields_fk_type_usage_plan_id
        FOREIGN KEY (type_usage_plan_id)
        REFERENCES accounting.usage_types (id),

    CONSTRAINT fields_fk_type_usage_fact_id
        FOREIGN KEY (type_usage_fact_id)
        REFERENCES accounting.usage_types (id),

    CONSTRAINT fields_fk_crop_plan_id
        FOREIGN KEY (crop_plan_id)
        REFERENCES accounting.crops (id),

    CONSTRAINT fields_fk_crop_fact_id
        FOREIGN KEY (crop_fact_id)
        REFERENCES accounting.crops (id),

    CONSTRAINT fields_fk_crop_variety_plan_id
        FOREIGN KEY (crop_variety_plan_id)
        REFERENCES accounting.crop_varieties (id),

    CONSTRAINT fields_fk_crop_variety_fact_id
        FOREIGN KEY (crop_variety_fact_id)
        REFERENCES accounting.crop_varieties (id),

    CONSTRAINT fields_fk_reclamation_system_id
        FOREIGN KEY (reclamation_system_id)
        REFERENCES reclamation.reclamation_systems (id)
);

CREATE INDEX fields_idx_geom
    ON vegetation.fields
    USING GIST (geom);

COMMIT;
