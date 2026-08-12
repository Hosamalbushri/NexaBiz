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

**Products (master data):** server-authoritative when the local row is already synced and the remote version is newer. If the local row is pending and the remote version advanced with different payload → **conflict** (no silent overwrite).

**Inventory stock counts:** treat counts as business-critical events. If remote version > local base version and `actualQuantity` differs → **conflict**. Do **not** use last-write-wins for counted quantities.

Resolution UI for conflicts is deferred; records are marked `SyncStatus.conflict` for operator review.

### Partial sync

Handlers are registered by `entityType` (`product`, `inventory_item`). Future modules add handlers only — they do not invent separate sync managers.

### Background sync

Foreground sync is implemented. Architecture keeps `SyncManager` free of UI so a future WorkManager / BGTask entrypoint can call `syncNow()` without redesign.

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
