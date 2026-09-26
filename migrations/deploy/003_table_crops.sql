-- Deploy gis-storage:002_table_crops to pg

BEGIN;

SET LOCAL ROLE gis_owner;

CREATE TABLE accounting.crops (

	id INTEGER GENERATED ALWAYS AS IDENTITY,

	name VARCHAR NOT NULL,

	color VARCHAR NOT NULL,

	note VARCHAR NULL,

	CONSTRAINT crops_pk PRIMARY KEY (id),

	CONSTRAINT crops_uq_color UNIQUE (color),

	CONSTRAINT crops_uq_name UNIQUE (name)

);

COMMIT;
