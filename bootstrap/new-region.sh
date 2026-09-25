#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m'

REGION="${1:?Usage: new-region.sh <region>}"

# Validate: lowercase letter first, then letters/digits/underscore, 2-31 chars.
if [[ ! "$REGION" =~ ^[a-z][a-z0-9_]{1,30}$ ]]; then
    echo -e "${RED}==> Invalid region name '${REGION}'.${NC}" >&2
    echo    "    Must match: ^[a-z][a-z0-9_]{1,30}$" >&2
    exit 2
fi

echo "==> Checking database: ${REGION}"

if psql -d postgres -tAc \
      "SELECT 1 FROM pg_database WHERE datname = '${REGION}'" | grep -q 1
then
    echo -e "${YELLOW}==> Database '${REGION}' already exists — skipping create.${NC}"
    echo -e "${YELLOW}==> Ensuring extensions are present.${NC}"
    psql -d "$REGION" -f /bootstrap/region/install_extensions.sql
    echo -e "${GREEN}==> Region '${REGION}' ready.${NC}"
    exit 0
fi

echo "==> Creating database: ${REGION}"
psql -d postgres -v region="$REGION" -f /bootstrap/region/create_database.sql

echo "==> Installing extensions in ${REGION}"
psql -d "$REGION" -f /bootstrap/region/install_extensions.sql

echo -e "${GREEN}==> Region created: ${REGION}${NC}"
