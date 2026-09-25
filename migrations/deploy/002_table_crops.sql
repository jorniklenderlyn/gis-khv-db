-- Deploy gis-storage:002_table_crops to pg

BEGIN;

CREATE TABLE accounting.crops (

	id integer GENERATED ALWAYS AS IDENTITY,

	name varchar NOT NULL,

	color varchar NOT NULL,

	note varchar NULL,

	CONSTRAINT "crops_pk" PRIMARY KEY (id),

	CONSTRAINT "crops_uq_color" UNIQUE (color),

	CONSTRAINT "crops_uq_name" UNIQUE (name)

);

COMMIT;
