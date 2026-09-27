# Database Documentation

## Table of Contents

- [Bootstrap](#bootstrap)
- [Add a New Region](#add-a-new-region)
- [Password Setup](#password-setup)
- [Database Structure](./db.drawio)
- [Roles](#roles)
- [Privileges Matrix](./privileges_matrix.ods)
- [Partitioning](#partitioning)
  - [Partitioned Tables](#partitioned-tables)
  - [Partitions Are Not Part of Migrations](#partitions-are-not-part-of-migrations)
  - [Creating Partitions](#creating-partitions)
  - [Naming Convention](#naming-convention)
  - [Constraints Imposed by Partitioning](#constraints-imposed-by-partitioning)
- [Migration](#migration)
  - [Schema Migration](#schema-migration)
    - [Migration Roles & Ownership](#migration-roles--ownership)
  - [Data Migration](#data-migration)
- [Monitoring](#monitoring)
- [Backup](#backup)

## Bootstrap

The bootstrap phase prepares the PostgreSQL cluster before any region database is created. It is split into two stages:

1. **Cluster init** — creates the required PostgreSQL roles. Roles are cluster-level objects shared across all databases, so they are created once per cluster.
2. **Region provisioning** — creates a per-region database and installs the required extensions in it. This step is repeated for every region added to the cluster.

The cluster init stage runs automatically on the initial container startup from `bootstrap/init/roles.sql` (mounted into PostgreSQL's `docker-entrypoint-initdb.d`). Role creation is idempotent: existing roles are left in place and the script continues.

The region provisioning stage is triggered explicitly by [`make new-region`](#add-a-new-region) and is described in the next section.

## Add a New Region

Each region is stored in its own database inside the shared PostgreSQL cluster. Region names must match the pattern `^[a-z][a-z0-9_]{1,30}$` (start with a lowercase letter; lowercase letters, digits or underscores after; 2–31 characters).

To create a new region and deploy the schema to it, run:

```bash
make new-region REGION=khv
```

The target performs the following steps:

* Runs `bootstrap/new-region.sh` inside the `postgres` container, which:
  * Checks whether the database `$REGION` already exists. If it does, the database is left untouched and only the extensions step is re-run.
  * Otherwise, creates the database from `bootstrap/region/create_database.sql`.
  * Installs the required extensions from `bootstrap/region/install_extensions.sql`.
* Registers a Sqitch target named `$REGION` pointing at `db:pg://gis_migrator@postgres:5432/$REGION` (skipped if the target already exists).
* Deploys the migrations to the new region with `sqitch deploy $REGION`.

The script is safe to re-run for an existing region: the database creation step is skipped and only extensions are (re)installed. To remove a region, use:

```bash
make drop-region REGION=khv
```

This prompts for confirmation, drops the database, and removes the Sqitch target.

## Password Setup

Passwords for login roles must **not be stored in the bootstrap scripts or committed to the repository**.

After the bootstrap phase has completed, connect to PostgreSQL through a **local connection** and set passwords for the required login roles:

```sql
ALTER ROLE <role_name> PASSWORD '<password>';
```

For example:

```sql
ALTER ROLE gis_app PASSWORD '<password>';
```

This approach ensures that role passwords are created locally during database setup and are not exposed in the project's source code.

The bootstrap phase is responsible for creating the roles and configuring their privileges. Passwords are configured separately after bootstrap.

## Roles

Roles are created during the bootstrap phase because PostgreSQL roles are cluster-level objects and are shared across all databases in the cluster.


|Name           |Login|Member of|Purposes|
|---------------|-----|---------|--------|
|gis_owner      |No   | -          | Owns database schemas and objects in gis database |
|gis_migrator   |Yes  | gis_owner  | Connects to the database and executes migrations |
|gis_app        |No   | -          | Defines privileges required by the webapp |
|gis_app_user   |Yes  | gis_app    | Webapp's database login; inherits privileges from `gis_app` |
|gis_read       |No   | -          | Defines read-only privileges |
|gis_read_user|Yes  | gis_read   | Login role for users/services that require read-only access |
|gis_edit     |No   | -          | `gis` database data editor group |
|gis_edit_user|Yes  | gis_edit   | Login role for `gis_edit` uses for editing data in db |

### Privileges

Privileges follow a deny-by-default model; see the [Privileges Matrix](./privileges_matrix.ods).

* `PUBLIC` has no access to region databases: `CONNECT`/`TEMPORARY` are revoked and `CREATE` on schema `public` is revoked (`bootstrap/region/database_access.sql`). `USAGE` on schema `public` is kept because PostGIS lives there.
* `gis_app`, `gis_edit`, `gis_read` get `CONNECT` on the region database (bootstrap) and schema/table privileges from migration `017_privileges`.
* Tables and partitions created later by `gis_owner` receive the same privileges automatically via `ALTER DEFAULT PRIVILEGES`.
* Every migration must run `SET LOCAL ROLE gis_owner;` right after `BEGIN;`. `verify/017_privileges.sql` fails if any object in the project schemas is not owned by `gis_owner`.

## Partitioning

### Partitioned Tables

The large, year-scoped tables in schema `vegetation` are declaratively partitioned:

| Table | Partition key chain | Depth |
|-------|---------------------|-------|
| `vegetation.fields` | `year` | 1 |
| `vegetation.ndvi_points` | `year` -> `pixel_size` -> `version` | 3 |
| `vegetation.evi_points` | `year` -> `pixel_size` -> `version` | 3 |
| `vegetation.analysis_results` | `year` | 1 |
| `vegetation.media` | `year` | 1 |

All levels use `PARTITION BY LIST`, because the key values are a small,
enumerable set (a year, a pixel size such as 10/20/30, a version number) rather
than a continuous range.

Only the **top level** (`PARTITION BY LIST (year)`) is declared by the
migrations, since that is the part of the partitioning that belongs to the
table definition itself. For `ndvi_points` and `evi_points` the nesting into
`pixel_size` and then `version` is expressed when the partitions themselves are
created — a year partition is created as `PARTITION BY LIST (pixel_size)`, a
pixel-size partition as `PARTITION BY LIST (version)`, and the version
partition is the leaf that actually stores rows.

### Partitions Are Not Part of Migrations

**Partitions are created on demand and are deliberately not part of any
migration.**

A migration describes the **logical schema** — tables, columns, constraints,
indexes, functions, privileges: the contract the application codes against.
A partition describes the **physical layout** — which subset of rows lives in
which physical relation. Adding the year 2027, the pixel size 30 or the
version 2 does not change the logical schema: no column appears, no constraint
changes, no query needs rewriting. The application sees the same
`vegetation.ndvi_points` before and after.

Consequences of keeping them out of the migrations:

* The set of partitions depends on the data a region actually has. Two regions
  deployed from the same migrations legitimately hold different partitions, so
  a partition list in a migration would be wrong for someone.
* Migrations stay deterministic and re-runnable. A migration that creates "the
  current year" would produce a different database depending on when it is
  deployed, and would need a new migration every year forever.
* `sqitch verify` checks that a table **is** partitioned by the expected key
  (see `migrations/verify/010_table_fields.sql` and friends); it does not check
  **which** partitions exist, because that is not a schema property.

Creating partitions is therefore an operational task, run by the process that
loads data for a new year / pixel size / version, or by an operator ahead of
that load. The only hard requirement is timing: a row cannot be inserted
before a leaf partition that accepts it exists. `INSERT` fails with
`no partition of relation ... found for row`.

### Creating Partitions

Partitions must be created by `gis_owner`, exactly like migration objects. That
way they are owned by `gis_owner` and `gis_app` / `gis_edit` / `gis_read` pick
up their privileges automatically from the `ALTER DEFAULT PRIVILEGES` set in
`017_privileges` — no `GRANT` per partition is needed.

Single-level tables (`fields`, `analysis_results`, `media`) — one statement per
year:

```sql
SET ROLE gis_owner;

CREATE TABLE vegetation.fields_2027
    PARTITION OF vegetation.fields
    FOR VALUES IN (2027);

CREATE TABLE vegetation.analysis_results_2027
    PARTITION OF vegetation.analysis_results
    FOR VALUES IN (2027);

CREATE TABLE vegetation.media_2027
    PARTITION OF vegetation.media
    FOR VALUES IN (2027);
```

Three-level tables (`ndvi_points`, `evi_points`) — the year and pixel-size
levels are themselves partitioned, only the version level stores rows:

```sql
SET ROLE gis_owner;

-- level 1: year, subdivided by pixel size
CREATE TABLE vegetation.ndvi_points_2027
    PARTITION OF vegetation.ndvi_points
    FOR VALUES IN (2027)
    PARTITION BY LIST (pixel_size);

-- level 2: pixel size, subdivided by version
CREATE TABLE vegetation.ndvi_points_2027_p20
    PARTITION OF vegetation.ndvi_points_2027
    FOR VALUES IN (20)
    PARTITION BY LIST (version);

-- level 3: version — the leaf, holds the rows
CREATE TABLE vegetation.ndvi_points_2027_p20_v1
    PARTITION OF vegetation.ndvi_points_2027_p20
    FOR VALUES IN (1);
```

Each new pixel size for an existing year adds a level-2 partition plus at least
one leaf; each new version for an existing pixel size adds only a leaf:

```sql
SET ROLE gis_owner;

-- new pixel size 10 within the existing year 2027
CREATE TABLE vegetation.ndvi_points_2027_p10
    PARTITION OF vegetation.ndvi_points_2027
    FOR VALUES IN (10)
    PARTITION BY LIST (version);

CREATE TABLE vegetation.ndvi_points_2027_p10_v1
    PARTITION OF vegetation.ndvi_points_2027_p10
    FOR VALUES IN (1);

-- reprocessed version 2 of the existing 2027 / 20 m data
CREATE TABLE vegetation.ndvi_points_2027_p20_v2
    PARTITION OF vegetation.ndvi_points_2027_p20
    FOR VALUES IN (2);
```

Indexes declared on the parent (`fields_idx_geom`, `ndvi_points_idx_geom`,
`ndvi_points_idx_field_id`, `media_idx_year_field_id`, …) and the primary key /
unique constraints are propagated to every new partition automatically. Nothing
has to be recreated per partition.

Dropping data for a year is a `DROP TABLE` of its top-level partition, which
removes the whole subtree:

```sql
SET ROLE gis_owner;
DROP TABLE vegetation.ndvi_points_2027;
```

To list what currently exists in a region:

```sql
SELECT c.oid::regclass AS partition,
       pg_get_expr(c.relpartbound, c.oid) AS bounds,
       pg_get_partkeydef(c.oid) AS subpartitioned_by
FROM pg_class AS c
INNER JOIN pg_inherits AS i ON i.inhrelid = c.oid
WHERE i.inhparent = 'vegetation.ndvi_points'::regclass
ORDER BY 1;
```

### Naming Convention

Partition names are not enforced by the database, but keep them predictable:

```text
<table>_<year>                      -- year level
<table>_<year>_p<pixel_size>        -- pixel size level
<table>_<year>_p<pixel_size>_v<ver> -- version level (leaf)
```

For example `ndvi_points_2027_p20_v1` is 2027, 20 m pixels, version 1.

### Constraints Imposed by Partitioning

PostgreSQL requires every partition key column to be part of every unique
index, which is why the keys are in the primary keys and unique constraints:

* `fields`: `PRIMARY KEY (year, id)`, `UNIQUE (year, hash)`
* `ndvi_points` / `evi_points`: `PRIMARY KEY (year, pixel_size, version, id)`,
  `UNIQUE (year, pixel_size, version, x, y)`
* `analysis_results`: `PRIMARY KEY (year, id)`, `UNIQUE (year, field_id, model_id)`
* `media`: `PRIMARY KEY (year, id)`, `UNIQUE (year, reference)`

`id` is therefore only unique **within** a year (and, for the point tables,
within a year/pixel size/version). Rows are referenced by the full composite
key — that is why the foreign keys to `fields` are `(year, field_id) ->
fields (year, id)`.

Queries should filter on `year` (and on `pixel_size` / `version` for the point
tables) so the planner can prune partitions; without those predicates every
partition is scanned.

## Migration

### Schema Migration

#### Adding a Migration

Create new changes only through `make add`, so every change starts from the project templates in `migrations/templates/`:

```bash
make add NAME=018_table_x NOTE="adds x" REQUIRES="010_table_fields 011_table_ndvi-points"
```

The templates already contain `SET LOCAL ROLE gis_owner;` in deploy/revert and a verify skeleton. Verify scripts must raise an error when an object is missing; a query that returns no rows is treated as success. The plan entry is signed with your `git config user.name` / `user.email`.

#### Migration Roles & Ownership

Database migrations are executed by the `gis_migrator` role. Before creating or modifying database objects, the migration session switches to the `gis_owner` role:

```sql
SET ROLE gis_owner;
```

`gis_owner` is a `NOLOGIN` role that owns the database schemas and objects created by migrations.

The purpose of using `SET ROLE gis_owner` is to keep **migration execution** and **object ownership** separate:

* `gis_migrator` — used to authenticate and execute migrations.
* `gis_owner` — owns schemas, tables, sequences, functions, and other database objects.
* `gis_app`, `gis_read`, and other roles receive privileges on these objects but do not own them.

Objects created after `SET ROLE gis_owner` are owned by `gis_owner`. This avoids making the migration login role the owner of database objects and provides a consistent ownership model.

The role relationship is:

```text
gis_migrator
     │
     │ SET ROLE
     ▼
 gis_owner
     │
     ├── schemas
     ├── tables
     ├── sequences
     ├── functions
     └── other database objects
```

The migration role therefore acts as the **migration executor**, while `gis_owner` acts as the **object owner**.

### Data Migration

During data migration, identity columns whose values are also being migrated must temporarily use **`GENERATED BY DEFAULT`** instead of **`GENERATED ALWAYS`**.

This allows the migration process to explicitly insert the existing `id` values from the source database. With `GENERATED ALWAYS`, PostgreSQL normally prevents explicit values from being inserted into the identity column.

Before the data migration:

```sql
ALTER TABLE <table_name>
ALTER COLUMN id SET GENERATED BY DEFAULT;
```

The migration can then insert the original `id` values:

```sql
INSERT INTO <table_name> (id, ...)
VALUES (..., ...);
```

After the data migration is complete, the identity column must be changed back to **`GENERATED ALWAYS`** to restore the normal protection against explicit `id` values:

```sql
ALTER TABLE <table_name>
ALTER COLUMN id SET GENERATED ALWAYS;
```

The identity sequence must also be synchronized with the migrated data so that subsequently generated IDs do not conflict with existing rows.

For example:

```sql
SELECT setval(
    pg_get_serial_sequence('<table_name>', 'id'),
    COALESCE(MAX(id), 1),
    COUNT(*) > 0
)
FROM <table_name>;
```

The expected migration lifecycle is:

```text
GENERATED ALWAYS
       │
       │ before data migration
       ▼
GENERATED BY DEFAULT
       │
       │ insert existing IDs
       ▼
Data migration completed
       │
       │ synchronize identity sequence
       ▼
GENERATED ALWAYS
```

## Monitoring