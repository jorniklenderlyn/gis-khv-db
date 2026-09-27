#!/usr/bin/env bash
# Restores legacy schemas ("Accounting" and year schemas "2019".."2025") from an
# old production dump into a region database, next to the new schemas.
# Migration scripts then copy data with plain INSERT ... SELECT inside one database;
# 99_drop_legacy.sql removes the legacy schemas afterwards.
#
# Usage (from the repo root): data-migration/00_restore_legacy.sh <region> <dump-file>
#   <dump-file> is a custom-format dump: pg_dump -Fc -d khv -f khv.dump
set -euo pipefail

REGION="${1:?Usage: 00_restore_legacy.sh <region> <dump-file>}"
DUMP="${2:?Usage: 00_restore_legacy.sh <region> <dump-file>}"

[[ -f "$DUMP" ]] || { echo "==> Dump not found: $DUMP" >&2; exit 1; }

# public (PostGIS) and backend (Django) are skipped
SCHEMAS=$(docker compose exec -T postgres pg_restore -l < "$DUMP" \
    | awk '$4 == "SCHEMA" && $6 ~ /^(Accounting|[0-9][0-9][0-9][0-9])$/ { print $6 }' \
    | sort -u)

[[ -n "$SCHEMAS" ]] || { echo "==> No legacy schemas found in $DUMP" >&2; exit 1; }

echo "==> Legacy schemas: $(echo $SCHEMAS)"

ARGS=()
CREATE_SQL=""
for s in $SCHEMAS; do
    ARGS+=(-n "$s")
    CREATE_SQL+="CREATE SCHEMA \"$s\";"
done

# pg_restore -n restores objects inside a schema but not the schema itself
docker compose exec -T -u postgres postgres \
    psql -v ON_ERROR_STOP=1 -X -q -d "$REGION" -c "$CREATE_SQL"

docker compose exec -T -u postgres postgres \
    pg_restore -d "$REGION" --no-owner --no-privileges --single-transaction \
    --exit-on-error "${ARGS[@]}" \
    < "$DUMP"

echo "==> Restored into database: $REGION"
