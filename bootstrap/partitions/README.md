# Region partition scripts

One SQL script per region, listing the partitions that region actually holds.
Each of the five partitioned tables gets its own anonymous PL/pgSQL `DO` block,
driven by a `v_years` declaration — one loop per table, so each table's year
list can diverge from the others without touching them.

Partitions are deliberately **not** part of the Sqitch migrations: two regions
deployed from the same plan legitimately hold different years, pixel sizes and
versions, so a partition list inside a migration would be wrong for someone.
See [docs/README.md#partitioning](../../docs/README.md#partitioning).

| File | Purpose |
|------|---------|
| `_template.sql` | Starting point for a new region. |
| `<region>.sql` | What that region holds, e.g. `khv.sql`. |

## Usage

```bash
make partitions REGION=khv
```

Re-running is safe: every statement is `CREATE TABLE IF NOT EXISTS`, so what
already exists is skipped with a `NOTICE`. The script ends with a check that
every partition is owned by `gis_owner` and a report of what the region now
has.

## Adding a year, pixel size or version

Edit the declarations in that table's `DO` block and re-run. A new year is one
entry in `v_years`:

```sql
v_years CONSTANT integer [] := ARRAY[
    2019, 2020, 2021, 2022, 2023, 2024, 2025, 2026
];
```

For `ndvi_points` and `evi_points`, a new pixel size or version is one row in
the `VALUES` list:

```sql
FROM (VALUES
    (10, ARRAY[1]),
    (20, ARRAY[1, 2]),
    (30, ARRAY[1, 2]),
    (60, ARRAY[1, 2])
) AS s (pixel_size, versions)
```

If one year ever diverges from the rest for a table, take it out of that
block's `v_years` and write that year's partitions out explicitly:

```sql
CREATE TABLE IF NOT EXISTS vegetation.fields_2026
PARTITION OF vegetation.fields FOR VALUES IN (2026);
```

## Adding a region

```bash
cp bootstrap/partitions/_template.sql bootstrap/partitions/<region>.sql
```

Edit the years, then `make partitions REGION=<region>`.

## Notes

* Everything runs after `SET LOCAL ROLE gis_owner`, so partitions are owned by
  `gis_owner` and inherit privileges from the `ALTER DEFAULT PRIVILEGES` in
  migration `017_privileges`. No per-partition `GRANT` is needed.
* Indexes and the primary key / unique constraints declared on the parent are
  propagated to every new partition automatically. Nothing is recreated here.
* `IF NOT EXISTS` matches on the **name**, not on the partition bound. Keep to
  the naming convention: a partition for the same bound created under a
  different name is not detected, and the `CREATE` then fails with
  `partition ... would overlap`.
* A leaf partition must exist before rows are inserted; `INSERT` otherwise
  fails with `no partition of relation ... found for row`.
