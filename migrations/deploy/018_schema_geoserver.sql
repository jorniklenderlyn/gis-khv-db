-- Deploy gis-storage:018_schema_geoserver to pg
-- requires: 017_privileges
-- requires: 010_table_fields
-- requires: 011_table_ndvi-points

BEGIN;

-- objects must be owned by gis_owner (checked by verify/017_privileges.sql)
SET LOCAL ROLE gis_owner;

-- Схема geoserver — контракт между БД и GeoServer. GeoServer публикует
-- только то, что лежит здесь, и не видит vegetation/accounting напрямую:
-- переименование колонки в таблице меняет вид, а не настройки слоёв
-- в data_dir GeoServer.
CREATE SCHEMA geoserver AUTHORIZATION gis_owner;

-- Виды выполняются с правами владельца (gis_owner), а не вызывающего —
-- security_invoker намеренно НЕ включён. Так gis_geoserver получает
-- SELECT только на эти виды, без доступа к базовым таблицам: через
-- GeoServer наружу уходят ровно перечисленные здесь колонки.

-- Поля. Владелец (owner_id) и служебные колонки (hash, note, удобрения)
-- в публикацию не входят: тайлы видит любой, кого пустил backend.
-- Названия культур и района — сразу строкой, чтобы стилю и подписи
-- не нужны были join'ы на стороне GeoServer.
CREATE VIEW geoserver.fields AS
SELECT
    f.id,
    f.year,
    f.geom,
    f.registr_number,
    f.area,
    f.district_id,
    d.name AS district_name,
    f.crop_plan_id,
    cp.name AS crop_plan_name,
    f.crop_fact_id,
    cf.name AS crop_fact_name,
    cf.color AS crop_fact_color,
    f.type_usage_fact_id,
    f.inspected
FROM vegetation.fields AS f
LEFT JOIN accounting.districts AS d ON f.district_id = d.id
LEFT JOIN accounting.crops AS cp ON f.crop_plan_id = cp.id
LEFT JOIN accounting.crops AS cf ON f.crop_fact_id = cf.id;

-- Точки NDVI. geom в таблице допускает NULL (его ставит триггер из x/y),
-- а GeoServer на строке без геометрии в MVT спотыкается — такие строки
-- отсекаются здесь. Недельные значения отдаются все: в векторном тайле
-- неделю выбирает стиль на клиенте, без 52 слоёв в GeoServer.
-- Фильтр по year/pixel_size/version — на стороне слоя (CQL или
-- параметры вида), секции отсекаются планировщиком и через вид.
CREATE VIEW geoserver.ndvi_points AS
SELECT
    p.id,
    p.year,
    p.pixel_size,
    p.version,
    p.geom,
    p.field_id,
    p.crop_plan_id,
    p.crop_pixel_result_id,
    p.ndvi_week_01, p.ndvi_week_02, p.ndvi_week_03, p.ndvi_week_04,
    p.ndvi_week_05, p.ndvi_week_06, p.ndvi_week_07, p.ndvi_week_08,
    p.ndvi_week_09, p.ndvi_week_10, p.ndvi_week_11, p.ndvi_week_12,
    p.ndvi_week_13, p.ndvi_week_14, p.ndvi_week_15, p.ndvi_week_16,
    p.ndvi_week_17, p.ndvi_week_18, p.ndvi_week_19, p.ndvi_week_20,
    p.ndvi_week_21, p.ndvi_week_22, p.ndvi_week_23, p.ndvi_week_24,
    p.ndvi_week_25, p.ndvi_week_26, p.ndvi_week_27, p.ndvi_week_28,
    p.ndvi_week_29, p.ndvi_week_30, p.ndvi_week_31, p.ndvi_week_32,
    p.ndvi_week_33, p.ndvi_week_34, p.ndvi_week_35, p.ndvi_week_36,
    p.ndvi_week_37, p.ndvi_week_38, p.ndvi_week_39, p.ndvi_week_40,
    p.ndvi_week_41, p.ndvi_week_42, p.ndvi_week_43, p.ndvi_week_44,
    p.ndvi_week_45, p.ndvi_week_46, p.ndvi_week_47, p.ndvi_week_48,
    p.ndvi_week_49, p.ndvi_week_50, p.ndvi_week_51, p.ndvi_week_52
FROM vegetation.ndvi_points AS p
WHERE p.geom IS NOT NULL;

-- Только чтение, только эта схема.
GRANT USAGE ON SCHEMA geoserver TO gis_geoserver;
GRANT SELECT ON ALL TABLES IN SCHEMA geoserver TO gis_geoserver;

-- Виды, добавленные в схему следующими миграциями, получат SELECT
-- автоматически, как таблицы в 017_privileges.
ALTER DEFAULT PRIVILEGES FOR ROLE gis_owner
    IN SCHEMA geoserver
    GRANT SELECT ON TABLES TO gis_geoserver;

COMMIT;
