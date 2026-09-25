#!/usr/bin/env bash

set -euo pipefail

SHARD_NAME="${1:?Usage: bootstrap.sh <shard_name>}"

echo "==> Creating roles"

psql \
    -d postgres \
    -f /bootstrap/01_roles.sql

echo "==> Creating database: ${SHARD_NAME}"

if psql \
    -d postgres \
    -tAc "SELECT 1 FROM pg_database WHERE datname = '${SHARD_NAME}'" \
    | grep -q 1
then
    echo "==> Database '${SHARD_NAME}' already exists, continuing"
else
    echo "==> Creating database: ${SHARD_NAME}"

    psql \
        -d postgres \
        -v shard_name="$SHARD_NAME" \
        -f /bootstrap/02_database.sql
fi

echo "==> Installing extensions"

psql \
    -d "$SHARD_NAME" \
    -f /bootstrap/03_extensions.sql

echo "==> Bootstrap completed: ${SHARD_NAME}"