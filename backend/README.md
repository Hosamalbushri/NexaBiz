# Experimental Synchronization Backend
#
# STATUS: EXPERIMENTAL — not production-ready for public internet.
# Purpose: exercise the existing Flutter offline-first SyncManager against a
# real HTTP API + PostgreSQL without replacing the Flutter sync engine.
#
# Release / CI / staging gates: see ../docs/deployment.md

## Architecture

```text
Flutter SyncManager
  → SyncEntityHandler (product|inventory_item|customer|account|sale)
    → RemoteSyncApi
      → HttpRemoteSyncApi  (or InMemoryRemoteSyncApi when SYNC_API_ENABLED=false)
        → FastAPI  POST /api/v1/sync/push | GET /pull | GET /meta
          → PostgreSQL (sync_entities, sync_changes, sync_operations)
```

Generic storage: entity payloads are JSONB keyed by `(company_id, entity_type, entity_uuid)`.
The sync layer is not duplicated per business module.

## Authentication (experimental identity layer)

Prefer JWT sessions over the legacy shared bearer:

```bash
curl -X POST http://127.0.0.1:8000/api/v1/auth/login \
  -H 'Content-Type: application/json' \
  -d '{
    "email":"ahmed@example.com",
    "password":"AhmedSales!123",
    "company_id":"00000000-0000-4000-8000-000000000001",
    "device_id":"<uuid>",
    "device_name":"Phone",
    "platform":"android"
  }'
```

Seed users: `admin@example.com` / `ChangeMeAdmin!123`, `ahmed@example.com` / `AhmedSales!123`.

See `docs/authentication.md`, `docs/authorization.md`, `docs/sync-security.md`.

Legacy shared bearer (`DEV_API_TOKEN`) still works when `ALLOW_DEV_TOKEN=true`
and seed identity exists — JWT is preferred.

## Quick start

```bash
cd backend
cp .env.example .env
docker compose up --build
```

- API: http://localhost:8000
- Docs: http://localhost:8000/docs
- Health: http://localhost:8000/health
- OpenAPI: http://localhost:8000/openapi.json

Default bearer token (from `.env`):

```text
Authorization: Bearer dev-sync-token-change-me
X-Company-Id: 00000000-0000-4000-8000-000000000001
X-User-Id:    00000000-0000-4000-8000-000000000002
X-Device-Id:  <unique-per-device>
```

## Local tests (no Docker)

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
pytest -q
```

Auth/RBAC tests need PostgreSQL (`DATABASE_URL` / `TEST_DATABASE_URL`). Sync API
tests use in-memory SQLite. Production-guard unit tests need no database.

```bash
./scripts/migrate.sh
APP_ENV=production JWT_SECRET="$(openssl rand -hex 32)" ALLOW_DEV_TOKEN=false \
  CORS_ORIGINS=https://app.example.com SEED_ADMIN_PASSWORD='Strong!change-me' \
  ./scripts/check_production_settings.sh
```

CI: GitHub Actions runs Flutter + backend pytest + secrets hygiene
(`.github/workflows/ci.yml`). See [`docs/deployment.md`](../docs/deployment.md).

## Flutter connection

Enable the HTTP remote (default remains in-memory so existing tests stay offline):

| Platform | Base URL |
| --- | --- |
| Flutter Web / desktop | `http://127.0.0.1:8000` |
| Android emulator | `http://10.0.2.2:8000` |
| iOS simulator | `http://127.0.0.1:8000` |
| Physical device | `http://<LAN-IP-of-host>:8000` (same Wi-Fi; allow firewall) |

```bash
# Physical Android/iOS device (host LAN IP must serve Docker on :8000)
flutter run \
  --dart-define=SYNC_API_ENABLED=true \
  --dart-define=SYNC_API_BASE_URL=http://192.168.8.110:8000 \
  --dart-define=SYNC_API_TOKEN=your-local-dev-token \
  --dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true \
  --dart-define=SYNC_API_DEVICE_ID=00000000-0000-4000-8000-0000000000a1

# Android emulator (special loopback to host)
flutter run \
  --dart-define=SYNC_API_ENABLED=true \
  --dart-define=SYNC_API_BASE_URL=http://10.0.2.2:8000 \
  --dart-define=SYNC_API_TOKEN=your-local-dev-token \
  --dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true \
  --dart-define=SYNC_API_DEVICE_ID=00000000-0000-4000-8000-0000000000a1
```

Use a **different** `SYNC_API_DEVICE_ID` (and optionally user id) for Device B.
Keep the same `SYNC_API_COMPANY_ID` so both devices share tenant data.

Without `SYNC_API_ALLOW_INSECURE_HTTP=true`, plain `http://` endpoints stay
disabled (Flutter fail-closed defaults). Prefer HTTPS outside the lab.

Phone and PC must be on the same Wi‑Fi; confirm from the phone browser:
`http://192.168.8.110:8000/health` → `{"status":"ok",...}`.

Android cleartext: ensure debug builds allow HTTP (`android:usesCleartextTraffic` /
network security config) when pointing at `http://` hosts.

## API surface (Flutter-compatible)

### POST `/api/v1/sync/push`

Body mirrors Flutter `RemoteSyncApi.push`:

```json
{
  "entity_type": "customer",
  "operation": {
    "operation_id": "…",
    "entity_type": "customer",
    "entity_id": "…",
    "type": "create",
    "payload": { "uuid": "…", "name": "Ahmed", "customerCode": "CUS-0001" },
    "base_version": 0
  }
}
```

Success → `SyncUploadAck` (`entity_id`, `remote_version`, `remote_updated_at`, `server_payload`).
Stale `base_version` → HTTP 409 `conflict` with `server_record` (maps to `SyncConflictFailure`).

### POST `/api/v1/sync/push/batch`

Optional multi-op push with per-operation `success` / `conflict` / `error` results.

### GET `/api/v1/sync/pull`

Query: `entity_type`, `cursor` **or** `since` (ISO-8601), `limit`.

Response:

```json
{
  "changes": [
    {
      "entity_id": "…",
      "entity_type": "customer",
      "version": 1,
      "updated_at": "…",
      "payload": { },
      "deleted": false,
      "sequence": 100,
      "operation": "create"
    }
  ],
  "next_cursor": 100,
  "has_more": false
}
```

`HttpRemoteSyncApi` prefers the server cursor; `SyncManager` still passes `since`
(`_lastSyncedAt`) without requiring SyncManager changes.

### GET `/api/v1/sync/meta/{entity_type}/{entity_id}`

Conflict probe used by handlers' `evaluateConflict`.

### GET `/health`

`{ "status": "ok", "database": "ok", … }`

## Why Flutter changes were minimal

| Change | Why |
| --- | --- |
| `HttpRemoteSyncApi` | Real HTTP adapter for existing `RemoteSyncApi` |
| `SyncApiConfig` | Base URL / token / tenant / device via dart-define |
| `remoteSyncApiProvider` | Swap InMemory ↔ HTTP when `SYNC_API_ENABLED=true` |
| `http` dependency | HTTP client |

**Unchanged:** `SyncManager`, `SyncQueue`, `ConflictResolver`, all `*SyncHandler`s,
repositories, payload shapes, soft-delete semantics, version conflict policy.

## Acceptance scenario (two devices)

1. Start backend (`docker compose up`).
2. Device A: create Customer "Ahmed" online → push → PostgreSQL row + change log.
3. Device B (same company, different device id): pull → receives Ahmed.
4. Device B offline edit → queue UPDATE → online push → server version++.
5. Device A pull → receives update.
6. Both edit with same `base_version` → one success, one structured conflict.

## Explicit non-goals

No microservices, brokers, Redis, Firebase, WebSockets, production IdP,
journal/currency/supplier domains, or automatic destructive conflict resolution.
