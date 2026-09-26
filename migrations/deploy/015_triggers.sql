-- Deploy gis-storage:015_triggers to pg

BEGIN;

-- площадь поля в м² (на эллипсоиде, без привязки к зоне UTM)
CREATE FUNCTION vegetation.set_area()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.area := public.ST_Area(NEW.geom::public.geography);
    RETURN NEW;
END;
$$;

-- хэш геометрии поля для fields_hash_uq
CREATE FUNCTION vegetation.set_hash()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.hash := md5(public.ST_AsText(NEW.geom));
    RETURN NEW;
END;
$$;

-- геометрия точки из x, y
CREATE FUNCTION vegetation.set_point_geom()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.geom := public.ST_SetSRID(public.ST_MakePoint(NEW.x, NEW.y), 4326);
    RETURN NEW;
END;
$$;

-- crop_plan_id точки из поля того же года
CREATE FUNCTION vegetation.set_crop_plan()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.crop_plan_id := (
        SELECT f.crop_plan_id
        FROM vegetation.fields AS f
        WHERE f.year = NEW.year
          AND f.id = NEW.field_id
    );
    RETURN NEW;
END;
$$;

-- fields
CREATE TRIGGER fields_trg_area
    BEFORE INSERT OR UPDATE ON vegetation.fields
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_area();

CREATE TRIGGER fields_trg_hash
    BEFORE INSERT OR UPDATE ON vegetation.fields
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_hash();

-- ndvi_points
CREATE TRIGGER ndvi_points_trg_geom
    BEFORE INSERT OR UPDATE ON vegetation.ndvi_points
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_point_geom();

CREATE TRIGGER ndvi_points_trg_crop_plan
    BEFORE INSERT OR UPDATE ON vegetation.ndvi_points
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_crop_plan();

-- evi_points
CREATE TRIGGER evi_points_trg_geom
    BEFORE INSERT OR UPDATE ON vegetation.evi_points
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_point_geom();

CREATE TRIGGER evi_points_trg_crop_plan
    BEFORE INSERT OR UPDATE ON vegetation.evi_points
    FOR EACH ROW EXECUTE FUNCTION vegetation.set_crop_plan();

COMMIT;
