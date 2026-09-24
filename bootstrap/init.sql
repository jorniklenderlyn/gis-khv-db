CREATE GROUP gis_owner;
CREATE GROUP gis_app;
CREATE GROUP gis_edit;
CREATE GROUP gis_read;

CREATE USER gis_migrator;
CREATE USER gis_app_user;
CREATE USER gis_edit_user;
CREATE USER gis_read_user;

GRANT gis_owner TO gis_migrator;
GRANT gis_app TO gis_app_user;
GRANT gis_edit TO gis_edit_user;
GRANT gis_read TO gis_read_user;

CREATE DATABASE gis 
    OWNER gis_owner
    TEMPLATE template0;

\connect gis

CREATE EXTENSION postgis;
