# ADR-006: Offline-First Synchronization

## Status

Accepted (implemented — foundation)

## Context

The Business Platform must remain fully usable without network access. Inventory counting and product catalog edits already write to local storage (Hive / Drift). A remote backend is not yet production-wired, but the app needs a durable sync architecture so local mutations can upload later and remote changes can download when connectivity returns.

## Decision

Adopt a shared **offline-first sync infrastructure** in Core:

| Piece | Role |
| --- | --- |
| Local DB (Hive + Drift) | Primary source of truth for UI |
| `SyncQueue` (Hive box `sync_queue`) | Durable pending mutations |
| `ConnectivityService` | Event-driven online/offline |
| `SyncManager` | Upload → download → conflict handling |
| `SyncEntityHandler` | Per-feature adapters (no per-feature sync engines) |
| `RemoteSyncApi` | Swappable remote (in-memory stub now; HTTP later) |

### Flow

```text
User action → Local DB → Immediate UI → Enqueue SyncOperation (pending)
→ Connectivity online → SyncManager upload → Server ack → mark synced
→ Pull remote changes → Merge locally
```

### IDs & timestamps

- Client-generated UUIDs for synchronizable rows (`Product.uuid`, `InventoryItem.id`)
- UTC `createdAt` / `updatedAt` / `lastSyncedAt`
- Soft delete via `deletedAt` tombstones until sync confirms

### Conflict strategy

**Creates (all entity types):** `create` means *ensure this UUID exists*.
It is never a version conflict. Dual-device system seeds (deterministic CoA
UUIDs, etc.) may push the same create; the server acks the authoritative row.
Clients enqueue creates with `baseVersion = 0`, skip pre-upload `getMeta`, and
drop pending create queue ops after a successful pull of the same UUID.

**Products (master data):** server-authoritative when the local row is already synced and the remote version is newer. If the local row is pending and the remote version advanced with different payload → **conflict** (no silent overwrite).

**Inventory stock counts:** treat counts as business-critical events. If remote version > local base version and `actualQuantity` differs → **conflict**. Do **not** use last-write-wins for counted quantities.

Resolution UI for conflicts is deferred; records are marked `SyncStatus.conflict` for operator review.

### Partial sync

Handlers are registered by `entityType` (`product`, `inventory_item`,
`customer`, `account`, `journal_entry`, `sale`). Future modules add handlers
only — they do not invent separate sync managers.

### Journal entries (amended 2026-08-16 — Phase 5)

**Decision:** sync `journal_entry` as offline-first events (same queue /
version / conflict model as other entities). Rejected alternative: server-side
ledger posting from sales (would diverge from ADR-006 and break offline
posting).

- Payload includes header + lines (`uuid`, amounts) and `accountCode` so peers
  can remount CoA UUIDs that differ per install.
- Sale apply-remote does **not** re-post journals; Device B receives the journal
  via `journal_entry` pull so UUIDs stay stable across devices.
- Linked sales journals keep `sourceType=sale` + `sourceId=sale.uuid`.

### Background sync

Foreground **non-blocking** sync is implemented: passes run asynchronously
without a modal overlay. [SyncBackgroundScheduler] drives automatic passes when
the user enables auto-sync (pending-queue debounce, connectivity restored, and
optional interval). Architecture keeps `SyncManager` free of UI so a future
WorkManager / BGTask entrypoint can call `syncNow()` without redesign.

### Opt-in (amended 2026-08-16)

Synchronization is **optional**. Default installs run **local-only**
(`sync_enabled = false`). When sync is on, **automatic background sync**
defaults to on (`sync_auto_enabled`) with a 15-minute interval; the user can
turn auto-sync off or choose change-only / other intervals. Manual Sync Now
always remains available and never blocks the UI.

### Observability (amended 2026-08-16 — Phase 6)

- Each sync pass gets a client `correlationId` (HTTP `X-Correlation-Id`).
- `SyncMetricsStore` (Hive) keeps a ring buffer of recent pass outcomes
  (uploaded / downloaded / duration / trigger).
- Optional Android WorkManager registers a periodic wake that stamps
  `SyncOsWakeSignal`; the foreground scheduler drains it into `syncNow`
  (full headless Drift sync in the isolate is deferred).

## Alternatives considered

- Online-only API-first UI (rejected — breaks offline counting)
- Per-feature sync services (rejected — duplication; Core rule is one sync infrastructure)
- Last-write-wins for inventory (rejected — unsafe for stock variance)

## Consequences

- UI/repositories write locally first; remote is sync-only
- `InMemoryRemoteSyncApi` is a stand-in until HTTP `RemoteSyncApi` is provided
- Drift products schemaVersion **2** adds sync columns
- Hive `InventoryItem` adapter fields 8–14 are additive sync metadata
- Settings exposes sync status + Sync Now; meaningful sync outcomes notify via the platform notification system
