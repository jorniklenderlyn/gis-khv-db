-- Deploy gis-storage:009_table_evi-points to pg

BEGIN;

CREATE TABLE vegetation.evi_points (
    id                      INTEGER GENERATED ALWAYS AS IDENTITY NOT NULL,
    year                    SMALLINT                       NOT NULL,
    pixel_size              SMALLINT                       NOT NULL,
    version                 SMALLINT                       NOT NULL,
    geom                    public.geometry(POINT, 4326)   NULL,
    x                       FLOAT8                         NOT NULL,
    y                       FLOAT8                         NOT NULL,
    evi_week_01          FLOAT8                           NOT NULL,
    evi_week_02          FLOAT8                           NOT NULL,
    evi_week_03          FLOAT8                           NOT NULL,
    evi_week_04          FLOAT8                           NOT NULL,
    evi_week_05          FLOAT8                           NOT NULL,
    evi_week_06          FLOAT8                           NOT NULL,
    evi_week_07          FLOAT8                           NOT NULL,
    evi_week_08          FLOAT8                           NOT NULL,
    evi_week_09          FLOAT8                           NOT NULL,
    evi_week_10          FLOAT8                           NOT NULL,
    evi_week_11          FLOAT8                           NOT NULL,
    evi_week_12          FLOAT8                           NOT NULL,
    evi_week_13          FLOAT8                           NOT NULL,
    evi_week_14          FLOAT8                           NOT NULL,
    evi_week_15          FLOAT8                           NOT NULL,
    evi_week_16          FLOAT8                           NOT NULL,
    evi_week_17          FLOAT8                           NOT NULL,
    evi_week_18          FLOAT8                           NOT NULL,
    evi_week_19          FLOAT8                           NOT NULL,
    evi_week_20          FLOAT8                           NOT NULL,
    evi_week_21          FLOAT8                           NOT NULL,
    evi_week_22          FLOAT8                           NOT NULL,
    evi_week_23          FLOAT8                           NOT NULL,
    evi_week_24          FLOAT8                           NOT NULL,
    evi_week_25          FLOAT8                           NOT NULL,
    evi_week_26          FLOAT8                           NOT NULL,
    evi_week_27          FLOAT8                           NOT NULL,
    evi_week_28          FLOAT8                           NOT NULL,
    evi_week_29          FLOAT8                           NOT NULL,
    evi_week_30          FLOAT8                           NOT NULL,
    evi_week_31          FLOAT8                           NOT NULL,
    evi_week_32          FLOAT8                           NOT NULL,
    evi_week_33          FLOAT8                           NOT NULL,
    evi_week_34          FLOAT8                           NOT NULL,
    evi_week_35          FLOAT8                           NOT NULL,
    evi_week_36          FLOAT8                           NOT NULL,
    evi_week_37          FLOAT8                           NOT NULL,
    evi_week_38          FLOAT8                           NOT NULL,
    evi_week_39          FLOAT8                           NOT NULL,
    evi_week_40          FLOAT8                           NOT NULL,
    evi_week_41          FLOAT8                           NOT NULL,
    evi_week_42          FLOAT8                           NOT NULL,
    evi_week_43          FLOAT8                           NOT NULL,
    evi_week_44          FLOAT8                           NOT NULL,
    evi_week_45          FLOAT8                           NOT NULL,
    evi_week_46          FLOAT8                           NOT NULL,
    evi_week_47          FLOAT8                           NOT NULL,
    evi_week_48          FLOAT8                           NOT NULL,
    evi_week_49          FLOAT8                           NOT NULL,
    evi_week_50          FLOAT8                           NOT NULL,
    evi_week_51          FLOAT8                           NOT NULL,
    evi_week_52          FLOAT8                           NOT NULL,
    crop_plan_id            INTEGER                           NULL, -- crop_plan_id из vegetation.fields (подтягивается триггером)
    crop_pixel_result_id    INTEGER                           NULL, -- id культуры из accounting.crops
    field_id                INTEGER                           NOT NULL, -- id поля из xxxx.xxx_list_of_fields
    note                    VARCHAR                        NULL,

    CONSTRAINT evi_points_pk PRIMARY KEY (year, pixel_size, version, id),

    CONSTRAINT evi_points_uq_x_y UNIQUE (year, pixel_size, version, x, y),
    -- FK
    CONSTRAINT evi_points_fk_field_id
        FOREIGN KEY (field_id) REFERENCES vegetation.fields (id),

    CONSTRAINT evi_points_fk_crop_plan_id
        FOREIGN KEY (crop_plan_id) REFERENCES accounting.crops (id),

    CONSTRAINT evi_points_fk_crop_pixel_result_id
        FOREIGN KEY (crop_pixel_result_id) REFERENCES accounting.crops (id)

) PARTITION BY LIST (year);

COMMIT;

