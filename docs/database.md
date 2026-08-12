# Database & Local Storage

## Technology

- **Hive** + **hive_flutter** — platform settings, notifications, sync queue, stock-count items
- **Drift** + **SQLite** (`sqlite3_flutter_libs`) — inventory products catalog
- Remote API used only through sync (`RemoteSyncApi`); UI never calls HTTP directly

See [ADR-004](adr/ADR-004-local-database.md), [ADR-005](adr/ADR-005-drift-products.md), and [ADR-006](adr/ADR-006-offline-first-sync.md).

## Initialization

Platform (splash / `AppBootstrap`):

1. `HiveInitializer.initialize()` → `Hive.initFlutter()` + open `app_settings`

Inventory module (lazy on first access):

1. `InventoryHive.openBox()` → `inventory_items`
2. `InventoryDatabase` via Drift → SQLite file for products

## Hive boxes

| Box name | Owner | Contents |
| --- | --- | --- |
| `app_settings` | App / Core | Theme mode, locale, dashboard/inventory service pins |
| `app_notifications` | App / Core | Notification history |
| `sync_queue` | Core sync | Durable `SyncOperation` queue |
| `inventory_items` | Inventory module | Stock-count `InventoryItem` entities |

Constants:

- Platform: `HiveBoxes.settings` in `lib/core/database/hive_boxes.dart`
- Inventory: `InventoryHive.boxName` in `lib/modules/inventory/data/inventory_hive.dart`

### Stock-count entity fields (Hive)

`itemCode`, `itemName`, `barcode`, `packSize`, `systemQuantity`, `actualQuantity`, `mainQuantity`, `subQuantity`, plus sync metadata: `id` (UUID), `createdAt`, `updatedAt`, `syncStatus`, `lastSyncedAt`, `version`, `deletedAt`

## Drift — products

- Database class: `InventoryDatabase` in `lib/modules/inventory/data/database/`
- Table: `products`

| Column | Notes |
| --- | --- |
| `id` | INTEGER PK |
| `uuid` | Client UUID (unique) |
| `item_code` | UNIQUE NOT NULL |
| `name` | NOT NULL |
| `barcode` | UNIQUE when set (nullable) |
| `pack_size` | INTEGER NOT NULL |
| `price` | REAL NOT NULL |
| `created_at` / `updated_at` | UTC epoch ms |
| `sync_status` | synced / pending / … |
| `last_synced_at` | UTC epoch ms nullable |
| `version` | Monotonic sync version |
| `deleted_at` | Soft-delete tombstone |

Products Excel import upserts by `item_code` and does **not** write Hive stock-count data. Stock-count import does **not** write products. Local imports enqueue sync operations when a `SyncQueue` is wired.

## Repository pattern

- Stock count: `InventoryRepository` → Hive
- Products: `ProductRepository` → Drift

**Rule:** UI must never open Hive boxes or the Drift database directly.

## Migrations

### Hive

**Unknown / Not configured** as a formal framework. Prefer additive adapter fields; document changes here.

### Drift

Use `schemaVersion` and `MigrationStrategy` on `InventoryDatabase`. Document each bump here.

Current products schema version: **2** (sync columns + uuid).

## Transactions

- Hive: `put` / `clear` / `replaceAll`
- Drift: batch upserts for products import; single-row insert/update/delete for CRUD

## Validation

- Domain counting: `CountingCalculator`
- Stock-count import: `ExcelImportDatasource` + `ImportValidationException`
- Products import: `ProductExcelImportDatasource` (required: code, name, pack size, price)
- Adapter / Drift coerce types defensively where needed

## Settings storage keys

`SettingsKeys.themeMode`, `SettingsKeys.locale`, dashboard/inventory service id lists in `settings_repository.dart`.
