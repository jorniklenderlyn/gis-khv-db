# Database Documentation

## Table of Contents

- [Bootstrap](#bootstrap)
- [Add a New Region](#add-a-new-region)
- [Password Setup](#password-setup)
- [Database Structure](./db.drawio)
- [Roles](#roles)
- [Privileges Matrix](./privileges_matrix.ods)
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