# Data Migration

One-time transfer of data from the legacy databases (`khv`, `amr`, `prm`: schemas `"Accounting"` and `"2019"`..`"2025"`) into a region database of the new schema. These scripts are not sqitch migrations: they depend on an external dump and run once per region.

## How it works

The legacy schemas are restored from a dump **into the region database itself**, next to the new schemas (`"Accounting"` and `accounting` are different schemas). Every step is then a plain `INSERT ... SELECT` inside one database; no `dblink`/`postgres_fdw`, no access to the old server. After a successful reconcile the legacy schemas are dropped.

| Step | File | What it does |
|---|---|---|
| 00 | `00_restore_legacy.sh` | restores `"Accounting"` and year schemas from the dump (skips `public`, `backend`) |
| 01 | `01_audit.sql` | read-only checks; **fails** on blockers or data loss |
| 02 | `02_dictionaries.sql` | dictionaries and reclamation systems, legacy ids kept |
| 03 | `03_fields.sql` | fields of all years, legacy ids kept, `year` added |
| 04 | `04_points.sql` | NDVI/EVI points, new ids, `pixel_size`/`version` from the table name |
| 05 | `05_media_analysis.sql` | media and analysis results, new ids |
| 06 | `06_sequences.sql` | moves identity sequences past the migrated ids |
| 07 | `07_reconcile.sql` | read-only comparison legacy vs migrated; **fails** on any mismatch |
| 99 | `99_drop_legacy.sql` | drops legacy schemas (run separately, after 07) |

Every SQL step runs in one transaction and refuses to run twice.

## Running

1. Get a fresh custom-format dump of the legacy database. For the final migration, stop writes to the legacy database first (read-only mode or stop the webapp), otherwise changes made after the dump are lost.
   ```bash
   pg_dump -Fc -h <old-host> -U read -d khv -f khv.dump
   ```
2. Create the region and deploy the schema: `make new-region REGION=khv`.
3. Create partitions of `vegetation.ndvi_points` and `vegetation.evi_points` for every year present in the dump (as `gis_owner`). `01_audit.sql` lists missing ones.
4. Run the migration:
   ```bash
   make migrate-data REGION=khv DUMP=path/to/khv.dump
   ```
   It stops at the first failing step. Read the audit/reconcile table in the output.
5. When `07_reconcile` passes: `make drop-legacy REGION=khv`.

To retry after a failure, recreate the region (`make drop-region`, `make new-region`, partitions) and run again: step 00 does not overwrite already restored legacy schemas.

## What changes during migration

* **Field ids are kept**, the primary key is `(year, id)`: the same id exists in different years. Every `UPDATE`/`DELETE` of `vegetation.fields` must filter by `year` as well as `id`.
* **Point, media and analysis ids are new.** Nothing references them, and legacy point tables are not guaranteed to have unique ids. A point is identified by `(year, pixel_size, version, x, y)`.
* **`area` is recomputed** in m² on the ellipsoid. Legacy values were in square degrees in older rows and in UTM m² in newer ones; they are not comparable.
* **`hash` and points' `crop_plan_id` are recomputed** by the triggers from the field.
* Legacy tables may have different column case (`"X"`/`"NDV1"` or `x`/`ndv1`); the scripts resolve names from the catalog.

## Stops on purpose

* Legacy columns with data that the new schema has no place for (khv 2021: `intern_number_dvniis`, `id_distric`). Decide where they go, then adapt `03_fields.sql`.
* Duplicate points by coordinates, duplicate field ids in a year, points without a field, a missing partition, an empty district name, a model name longer than 255 characters. Duplicates are not removed silently: clean the legacy data and rerun.

## Tested on

* `amr` dump of 2024-08-02 (2021–2022): 1 412 fields, 261 792 points, all values match. The dump itself had 5 267 duplicated points (the table had no constraints at the time); the audit stops on them.
* Structure of the production `khv` schema (all years, all NDVI/EVI tables, reclamation, 2021 extra columns) with synthetic rows.

Not yet run on current production dumps of `khv`, `amr`, `prm`.
