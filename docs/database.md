# Database & Local Storage

## Technology

- **Hive** + **hive_flutter** — platform settings, notifications, sync queue, stock-count items
- **Drift** + **SQLite** (`sqlite3_flutter_libs`) — inventory products catalog; accounting Chart of Accounts; customers master
- Remote API used only through sync (`RemoteSyncApi`); UI never calls HTTP directly

See [ADR-004](adr/ADR-004-local-database.md), [ADR-005](adr/ADR-005-drift-products.md), [ADR-006](adr/ADR-006-offline-first-sync.md), [ADR-007](adr/ADR-007-accounting-chart-of-accounts.md), and [ADR-009](adr/ADR-009-customers-module.md).

## Initialization

Platform (splash / `AppBootstrap`):

1. `HiveInitializer.initialize()` → `Hive.initFlutter()` + open `app_settings`

Inventory module (lazy on first access):

1. `InventoryHive.openBox()` → `inventory_items`
2. `InventoryDatabase` via Drift → SQLite file for products

Accounting module (lazy on first access):

1. `AccountingDatabase` via Drift → SQLite file for accounts
2. Default Chart of Accounts seeded once when the table is empty

Customers module (lazy on first access):

1. `CustomersDatabase` via Drift → SQLite file for customers

Sales module (lazy on first access):

1. `SalesDatabase` via Drift → SQLite file for sales / items / payments

## Hive boxes

| Box name | Owner | Contents |
| --- | --- | --- |
| `app_settings` | App / Core | Theme, locale, company profile, dashboard/inventory pins, accounting mode |
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

## Drift — accounts (Accounting)

- Database class: `AccountingDatabase` in `lib/modules/accounting/data/database/`
- Tables: `accounts`, `currency_rates`, `voucher_books`, `journal_entries`, `journal_lines`
- Schema version: **6**
- Sync entity types: `account`, `journal_entry`, `fiscal_year`, `currency_rate` (voucher books remain local for now)

| Column | Notes |
| --- | --- |
| `id` | INTEGER PK |
| `uuid` | Client UUID (unique); journal lines reference this |
| `parent_id` | Parent account UUID (nullable for roots) |
| `account_code` | UNIQUE business code (not the DB id) |
| `name` / `description` | Display fields |
| `account_type` | asset / liability / equity / revenue / expense |
| `normal_balance` | debit / credit (derived from type) |
| `level` | Hierarchy depth (roots = 0) |
| `is_group` | Group vs posting account |
| `is_active` / `is_system_account` | Soft deactivate + system protection |
| `created_at` / `updated_at` | UTC epoch ms |
| `sync_status` / `last_synced_at` / `version` / `deleted_at` | Offline-first metadata |

Default system accounts are seeded locally as `synced` (no queue flood). User mutations enqueue `SyncOperation` rows via Core `SyncQueue`.

Trading + VAT system leaves (additive; see `DefaultChartOfAccounts`): petty cash `1213`, inventory in transit `1235`, VAT input `1250`, prepaid `1260`, other current assets `1290`, suppliers group `2111`, VAT output `2130`, accrued expenses `2140`, customer advances `2150`, long-term loans `2210`, other revenue group `4200` + purchase discounts `4210`, inventory adjustments `5150`, sales returns `5160`, sales discounts `5170`, bank charges `5500`, depreciation `5600`, advertising `5700`, shipping `5800`, maintenance `5850`. Re-running seed inserts any missing `system:*` rows.

### Drift — currency rates (Accounting)

| Column | Notes |
| --- | --- |
| `id` | INTEGER PK |
| `currency_code` | UNIQUE (e.g. `USD`) |
| `rate_to_base` | REAL — units of company base currency per 1 unit of this currency |
| `updated_at` | UTC epoch ms |
| `notes` | Optional |

Base currency comes from company setup (`CompanyProfile.defaultCurrencyCode`).

Currencies are **enabled on demand**: the rates list shows the base currency plus only currencies that have a `currency_rates` row (not the full catalog). The catalog (`AppCurrencies`, including YER) is used when picking a currency to add.

Upserting a rate also writes/updates **`currency_rate_history`** for the as-of UTC day (`currency_code` + `as_of_date` unique). Lookups for posting/closing use `getRateOn(code, date)` (on or before the date).

### Drift — journal entries / lines (Accounting)

Schema bump through **v11**. Local ledger (sync queue for journals where enabled).

| Table | Notes |
| --- | --- |
| `journal_entries` | Header: `entry_date`, `voucher_number`, `voucher_type`, description, currency, `is_posted`, `source_type`/`source_id` (e.g. `sale` + sale uuid), soft `deleted_at` |
| `journal_lines` | `entry_uuid`, `account_uuid`, `debit`/`credit`, `exchange_rate_to_base`, `base_debit`/`base_credit`, line description, currency, `sort_order` |

Multi-currency journals must balance in **base** amounts. Period-end FX revaluation uses asset/liability foreign positions from these base columns.

### Drift — voucher books (Accounting)

| Column | Notes |
| --- | --- |
| `id` | INTEGER PK |
| `uuid` | Client UUID (unique) |
| `parent_id` | Parent **section group** uuid (null for section roots) |
| `name` | Display name |
| `book_type` | Section or leaf kind (`sales`, `salesReturns`, `receipts`, `payments`, `purchases`, `purchaseReturns`, `journal`) |
| `is_group` | `1` = section folder (no numbering); `0` = leaf numbering book |
| `next_number` | Current number in the book / next to allocate (≥ 1) — leaf only |
| `end_number` | Last number available in the book (≥ current) |
| `pad_length` | Legacy unused column |
| `is_active` | Inactive leaves cannot allocate |
| `notes` | Optional |
| `created_at` / `updated_at` | UTC epoch ms |

Default section groups (Sales / Receipts / Payments / Purchases / Journal) are ensured on open, and **one default leaf book per kind** is seeded when missing (see `DefaultVoucherBooks`). UI: section list → section page with **tabs per leaf type** (e.g. Sales / Sales returns), each with its own list + add action. Each section may have **many** child books. Setup UI: `/accounting/voucher-books`. Allocation via `VoucherBookRepository.allocateNextNumber` (atomic, leaf only). See ADR-010.

### Drift — journal entries / lines (legacy note)

Schema history included bump **5 → 6**. Local ledger; journals may enqueue sync.

| Table | Notes |
| --- | --- |
| `journal_entries` | Header: `entry_date`, `voucher_number`, `voucher_type`, description, currency, `is_posted`, `source_type`/`source_id` (e.g. `sale` + sale uuid), soft `deleted_at` |
| `journal_lines` | `entry_uuid`, `account_uuid`, `debit`/`credit`, line description, currency, `sort_order` |

Indexes: entry date, source pair, line account, line entry. Upsert by `source_type` + `source_id` (replace in place). Standalone credit sales sync `Dr` customer / `Cr` `4100` on save with `is_posted` matching sale status; post marks both posted (ADR-008). Account statement reads these lines for opening + running balance.

## Drift — customers (Customers)

- Database class: `CustomersDatabase` in `lib/modules/customers/data/database/`
- Table: `customers`
- Schema version: **1**
- Sync entity type: `customer`

| Column | Notes |
| --- | --- |
| `id` | INTEGER PK |
| `uuid` | Client UUID (unique); sync / future FKs |
| `customer_code` | UNIQUE business code (e.g. `12210001` from parent CoA `1221`) |
| `name` / `phone` / `email` / `address` / `notes` | Contact fields |
| `is_active` | Soft deactivate |
| `account_id` | Opaque Account.uuid (nullable); never auto-created |
| `external_id` / `data_source` | Local vs external ERP identity |
| `created_at` / `updated_at` | UTC epoch ms |
| `sync_status` / `last_synced_at` / `version` / `deleted_at` | Offline-first metadata |

## Drift — sales (Sales)

- Database class: `SalesDatabase` in `lib/modules/sales/data/database/`
- Tables: `sales`, `sale_items`, `sale_payments`
- Schema version: **1**
- Sync entity type: `sale`
- SQLite file: `sales_master`

| Table | Notes |
| --- | --- |
| `sales` | Header: number, customer uuid snapshot, totals, tax, payment, status, external refs, sync |
| `sale_items` | Lines with product uuid + name/code/barcode snapshots, main/sub qty + packSize, effective qty, price, discounts |
| `sale_payments` | Payment rows for multi-payment expansion |

Customer and product FKs are opaque uuids — no cross-DB foreign keys. See ADR-011.

## Repository pattern

- Stock count: `InventoryRepository` → Hive
- Products: `ProductRepository` → Drift
- Accounts: `AccountRepository` → Drift (Accounting module)
- Currency rates: `CurrencyRateRepository` → Drift (Accounting module)
- Customers: `CustomerRepository` → Drift (Customers module)
- Sales: `SaleRepository` → Drift (Sales module)

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
- Customers import: `CustomerExcelImportDatasource` (required: code, name; optional phone/email/address/notes/external id)
- Adapter / Drift coerce types defensively where needed

## Settings storage keys

`SettingsKeys.themeMode`, `SettingsKeys.locale`, dashboard/inventory service id lists in `settings_repository.dart`. Accounting mode key is legacy/unused (always local).
