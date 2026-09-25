-- Group roles (NOLOGIN): hold privileges.
CREATE ROLE gis_owner    NOLOGIN;
CREATE ROLE gis_app      NOLOGIN;
CREATE ROLE gis_edit     NOLOGIN;
CREATE ROLE gis_read     NOLOGIN;

-- Login roles: real users / service accounts.
CREATE ROLE gis_migrator  LOGIN;
CREATE ROLE gis_app_user  LOGIN;
CREATE ROLE gis_edit_user LOGIN;
CREATE ROLE gis_read_user LOGIN;

-- Memberships: login roles inherit their group's privileges.
GRANT gis_owner TO gis_migrator;
GRANT gis_app   TO gis_app_user;
GRANT gis_edit  TO gis_edit_user;
GRANT gis_read  TO gis_read_user;
