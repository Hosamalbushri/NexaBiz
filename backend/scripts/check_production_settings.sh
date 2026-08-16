#!/usr/bin/env sh
# Fail fast if APP_ENV=production|staging with unsafe settings.
# Usage:
#   cd backend
#   APP_ENV=production JWT_SECRET=... ALLOW_DEV_TOKEN=false CORS_ORIGINS=https://x \
#     SEED_ADMIN_PASSWORD='...' ./scripts/check_production_settings.sh
set -eu
cd "$(dirname "$0")/.."

if [ -x .venv/bin/python ]; then
  PY=.venv/bin/python
elif command -v python3 >/dev/null 2>&1; then
  PY=python3
else
  PY=python
fi

"$PY" - <<'PY'
from app.core.config import Settings, get_settings

get_settings.cache_clear()
settings = Settings()
settings.assert_safe_for_environment()
print(f"OK — app_env={settings.app_env!r} allow_dev_token={settings.allow_dev_token}")
PY
