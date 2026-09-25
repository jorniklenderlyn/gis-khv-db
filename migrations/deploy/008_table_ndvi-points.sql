-- Deploy gis-storage:008_table_ndvi-points to pg

BEGIN;

CREATE TABLE gis_vegetation.ndvi_points (
    id                      integer GENERATED ALWAYS AS IDENTITY NOT NULL,
    region                  text                           NOT NULL,
    year                    smallint                       NOT NULL,
    pixel_size              smallint                       NOT NULL,
    version                 smallint                       NOT NULL,
    geom                    public.geometry(point, 4326)   NULL,
    x                       float8                         NOT NULL,
    y                       float8                         NOT NULL,
    ndvi_week_01          float8                           NOT NULL,
    ndvi_week_02          float8                           NOT NULL,
    ndvi_week_03          float8                           NOT NULL,
    ndvi_week_04          float8                           NOT NULL,
    ndvi_week_05          float8                           NOT NULL,
    ndvi_week_06          float8                           NOT NULL,
    ndvi_week_07          float8                           NOT NULL,
    ndvi_week_08          float8                           NOT NULL,
    ndvi_week_09          float8                           NOT NULL,
    ndvi_week_10          float8                           NOT NULL,
    ndvi_week_11          float8                           NOT NULL,
    ndvi_week_12          float8                           NOT NULL,
    ndvi_week_13          float8                           NOT NULL,
    ndvi_week_14          float8                           NOT NULL,
    ndvi_week_15          float8                           NOT NULL,
    ndvi_week_16          float8                           NOT NULL,
    ndvi_week_17          float8                           NOT NULL,
    ndvi_week_18          float8                           NOT NULL,
    ndvi_week_19          float8                           NOT NULL,
    ndvi_week_20          float8                           NOT NULL,
    ndvi_week_21          float8                           NOT NULL,
    ndvi_week_22          float8                           NOT NULL,
    ndvi_week_23          float8                           NOT NULL,
    ndvi_week_24          float8                           NOT NULL,
    ndvi_week_25          float8                           NOT NULL,
    ndvi_week_26          float8                           NOT NULL,
    ndvi_week_27          float8                           NOT NULL,
    ndvi_week_28          float8                           NOT NULL,
    ndvi_week_29          float8                           NOT NULL,
    ndvi_week_30          float8                           NOT NULL,
    ndvi_week_31          float8                           NOT NULL,
    ndvi_week_32          float8                           NOT NULL,
    ndvi_week_33          float8                           NOT NULL,
    ndvi_week_34          float8                           NOT NULL,
    ndvi_week_35          float8                           NOT NULL,
    ndvi_week_36          float8                           NOT NULL,
    ndvi_week_37          float8                           NOT NULL,
    ndvi_week_38          float8                           NOT NULL,
    ndvi_week_39          float8                           NOT NULL,
    ndvi_week_40          float8                           NOT NULL,
    ndvi_week_41          float8                           NOT NULL,
    ndvi_week_42          float8                           NOT NULL,
    ndvi_week_43          float8                           NOT NULL,
    ndvi_week_44          float8                           NOT NULL,
    ndvi_week_45          float8                           NOT NULL,
    ndvi_week_46          float8                           NOT NULL,
    ndvi_week_47          float8                           NOT NULL,
    ndvi_week_48          float8                           NOT NULL,
    ndvi_week_49          float8                           NOT NULL,
    ndvi_week_50          float8                           NOT NULL,
    ndvi_week_51          float8                           NOT NULL,
    ndvi_week_52          float8                           NOT NULL,
    crop_plan_id            int4                           NULL, -- crop_plan_id из gis_vegetation.fields (подтягивается триггером)
    crop_pixel_result_id    int4                           NULL, -- id культуры из accounting.crops
    field_id                int4                           NOT NULL, -- id поля из xxxx.xxx_list_of_fields
    note                    varchar                        NULL,                  NOT NULL DEFAULT now(),

    CONSTRAINT ndvi_points_pk PRIMARY KEY (region, year, pixel_size, version, id),

    CONSTRAINT ndvi_points_uq_x_y UNIQUE (region, year, pixel_size, version, x, y),

    CONSTRAINT ndvi_points_fk_field_id
        FOREIGN KEY (field_id) REFERENCES gis_vegetation.fields (id),

    CONSTRAINT ndvi_points_fk_crop_plan_id
        FOREIGN KEY (crop_plan_id) REFERENCES accounting.crops (id),

    CONSTRAINT ndvi_points_fk_crop_pixel_result_id
        FOREIGN KEY (crop_pixel_result_id) REFERENCES accounting.crops (id)

) PARTITION BY LIST (region);

-- these propagate automatically to every current/future partition
CREATE INDEX ndvi_points_idx_geom ON ndvi_points USING gist (geom);
CREATE INDEX ndvi_points_idx_field_id ON ndvi_points (field_id);
CREATE INDEX ndvi_points_idx_crop_plan_id ON ndvi_points (crop_plan_id);
CREATE INDEX ndvi_points_idx_crop_pixel_result_id ON ndvi_points (crop_pixel_result_id);

COMMENT ON TABLE ndvi_points IS 'NDVI pixel points, partitioned by region -> year -> pixel_size -> version';


COMMIT;
