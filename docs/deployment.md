# Deployment & release (Phase 7)

## Status

The sync API remains **experimental**, but PR merges and LAN staging must pass
the gates below before any wider exposure.

## CI gates (GitHub Actions)

Workflow: [`.github/workflows/ci.yml`](../.github/workflows/ci.yml)

| Job | Blocks merge when |
| --- | --- |
| Flutter analyze + test | `flutter analyze` or `flutter test` fails |
| Backend pytest | `alembic upgrade head` or `pytest` fails (Postgres service) |
| Secrets hygiene | Tracked `.env` / keystore files (except `*.example`) |

Run locally:

```bash
# Flutter
flutter pub get && flutter analyze && flutter test

# Backend (Docker Postgres or compose)
cd backend
cp .env.example .env   # local only
docker compose up -d db
alembic upgrade head
pytest -q
./scripts/check_production_settings.sh   # with APP_ENV=production + real secrets
```

## Secrets

| Rule | Detail |
| --- | --- |
| Never commit | `.env`, `.env.production`, `*.jks`, `*.keystore`, `*.p12` |
| Templates only | [`backend/.env.example`](../backend/.env.example), [`backend/.env.production.example`](../backend/.env.production.example) |
| Production | `ALLOW_DEV_TOKEN=false`, unique `JWT_SECRET`, `CORS_ORIGINS` ≠ `*`, `AUTH_RATE_LIMIT_PER_MINUTE` > 0 |
| Seed passwords | Change `SEED_ADMIN_PASSWORD` before first shared deploy |

`Settings.assert_safe_for_environment()` refuses unsafe production settings at API startup.

## Migrations

Docker image CMD already runs `alembic upgrade head` before uvicorn.

Manual / staging:

```bash
cd backend
./scripts/migrate.sh
```

Always migrate **before** rolling new API replicas that depend on new columns.

## Staging → canary

1. **Staging (LAN / private VPC)**  
   - Deploy API behind TLS reverse proxy only.  
   - `APP_ENV=staging` or `production` with production-like secrets.  
   - Point 1–2 Flutter devices with `--dart-define=SYNC_API_BASE_URL=https://…`.  
   - Smoke: login JWT, push/pull sale + journal, revoke device.

2. **Canary**  
   - 5–10% of devices (or one branch office) on the new build.  
   - Watch sync metrics / correlation ids in logs for 24–48h.  
   - Rollback = previous container image + prior migration only if forward-compatible.

3. **General release**  
   - Signed Android App Bundle / APK.  
   - Changelog of sync/auth/accounting changes.  
   - Confirm `allow_dev_token` remains false in the live env.

## Flutter release build (Android)

```bash
flutter build appbundle --release \
  --dart-define=SYNC_API_ENABLED=true \
  --dart-define=SYNC_API_BASE_URL=https://sync.example.com \
  --dart-define=SYNC_API_TOKEN="$SYNC_API_TOKEN" \
  --dart-define=SENTRY_ENABLED=true \
  --dart-define=SENTRY_DSN="$SENTRY_DSN" \
  --dart-define=SENTRY_ENVIRONMENT=production
```

Optional crash reporting (fail-closed unless both flags are set):

| Dart define | Purpose |
| --- | --- |
| `SENTRY_ENABLED` | Must be `true` to activate Sentry |
| `SENTRY_DSN` | Project DSN (CI secret — never commit) |
| `SENTRY_ENVIRONMENT` | e.g. `production`, `staging` (defaults: release→production, debug→development) |

Local errors are always written to `logs/app_errors.log` via `AppErrorLog`.
Sentry receives the same events when enabled.

Do **not** ship builds with:

- `SYNC_API_ENABLED` defaulting on
- baked-in shared tokens
- `SYNC_API_ALLOW_INSECURE_HTTP=true`
- HTTP (non-TLS) base URLs

Store signing keys outside git (Play App Signing or CI secrets).

## Definition of done for a release PR

- [ ] CI green on the PR  
- [ ] No secrets in the diff  
- [ ] Migration included when schema changed  
- [ ] Staging smoke passed  
- [ ] Canary plan noted in the PR description  
- [ ] Sync dart-defines are explicit HTTPS + unique token (or sync left disabled)  
- [ ] Local admin password changed from the first-install default  
- [ ] Sentry DSN supplied via CI secret when crash reporting is required
