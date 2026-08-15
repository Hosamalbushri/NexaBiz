# ADR-010: Experimental Synchronization HTTP Backend

## Status

Accepted (experimental)

## Context

ADR-006 introduced an offline-first Flutter sync stack (`SyncManager`, `SyncQueue`,
`SyncEntityHandler`, `RemoteSyncApi`) with `InMemoryRemoteSyncApi` as a stand-in.

We need a **small real backend** (HTTP + PostgreSQL) to validate multi-device
push/pull, conflicts, idempotency, and soft deletes — without building the full
production platform API.

## Decision

1. Add `backend/` FastAPI + PostgreSQL + Alembic (Docker Compose).
2. Keep a **generic** sync store (`sync_entities` JSONB + `sync_changes` cursor +
   `sync_operations` idempotency) scoped by `company_id`.
3. Match Flutter contracts:
   - `POST /api/v1/sync/push` ↔ `RemoteSyncApi.push`
   - `GET /api/v1/sync/pull` ↔ `RemoteSyncApi.pull` (`since` + `cursor`)
   - `GET /api/v1/sync/meta/...` ↔ `RemoteSyncApi.getMeta`
   - HTTP 409 `conflict` ↔ `SyncConflictFailure`
4. Add Flutter `HttpRemoteSyncApi` behind `SYNC_API_ENABLED` dart-define.
   Do **not** replace `SyncManager` / `SyncQueue` / handlers.

## Consequences

- Local multi-device sync demos are possible against one PostgreSQL.
- Auth is intentionally a shared Bearer token + headers (not production identity).
- Cursor-based pull is available; SyncManager still uses in-memory `_lastSyncedAt`.
- Follow-up work documented in `docs/sync-implementation-summary.md`:
  - HTTP enabled by default for LAN device testing
  - Customer/account business-key merge on pull (same code, different UUID)
  - Device-scoped silent numeric lanes (plain integers, no device label in UI) + voucher-book number blocks
- This backend is labeled **experimental** and is not a production system of record.
