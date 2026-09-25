-- bootstrap/01_roles.sql

DO $$
DECLARE
    role_name text;
BEGIN
    FOREACH role_name IN ARRAY ARRAY[
        'gis_owner',
        'gis_app',
        'gis_edit',
        'gis_read',
        'gis_migrator',
        'gis_app_user',
        'gis_edit_user',
        'gis_read_user'
    ]
    LOOP
        IF NOT EXISTS (
            SELECT FROM pg_roles
            WHERE rolname = role_name
        ) THEN
            EXECUTE format('CREATE ROLE %I', role_name);
            RAISE NOTICE 'Created role %', role_name;
        ELSE
            RAISE NOTICE 'Role % already exists', role_name;
        END IF;
    END LOOP;

    GRANT gis_owner TO gis_migrator;
    GRANT gis_app TO gis_app_user;
    GRANT gis_edit TO gis_edit_user;
    GRANT gis_read TO gis_read_user;

    RAISE NOTICE 'Role memberships configured';
END
$$;