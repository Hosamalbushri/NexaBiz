#!/usr/bin/env sh
# Apply Alembic migrations then print current revision.
# Usage (from backend/):
#   ./scripts/migrate.sh
#   APP_ENV=production ./scripts/migrate.sh
set -eu
cd "$(dirname "$0")/.."

if [ ! -f alembic.ini ]; then
  echo "Run from backend/ (alembic.ini missing)" >&2
  exit 1
fi

echo "→ alembic upgrade head"
alembic upgrade head
echo "→ alembic current"
alembic current
echo "OK"
