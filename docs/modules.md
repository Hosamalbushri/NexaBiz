# Modules

## Module contract

Every business module **extends** `AppModule` (so default hooks like
`hasSettings` / `buildSettingsSections` / `onSettingsReset` are inherited):

`lib/core/modules/app_module.dart`

Required concepts:

- `id` — stable slug
- `nameKey` — analytics/l10n key
- `icon`
- `rootRoute`
- `isEnabled`
- `label(context)` / optional `description(context)`
- `routes`
- optional `providerOverrides`
- optional settings: `hasSettings`, `buildSettingsSections(context)`, `onSettingsReset(ref)`

Module-specific settings live in the module package and are composed by the platform Settings page through `AppModule` — the Settings page must not import concrete module settings widgets.

## Registration

Modules are registered only in:

```text
lib/app/bootstrap/module_bootstrap.dart
```

Current registry:

```dart
ModuleRegistry(const [
  InventoryModule(),
  AccountingModule(),
  CustomersModule(),
  SalesModule(),
]);
```

`moduleRegistryProvider` throws if not overridden — App bootstrap is mandatory.

## Current modules

### Inventory — implemented

Path: `lib/modules/inventory/`

| Area | Routes / entry |
| --- | --- |
| Hub | `/inventory` — customizable/reorderable service cards (Stock count, Products) |
| Stock count hub | `/inventory/stock-count` — grid of count / import / reports |
| Count | `/inventory/stock-count/count` |
| Count details | `/inventory/stock-count/count/details` |
| Stock import | `/inventory/stock-count/import` |
| Reports | `/inventory/stock-count/reports` |
| Products hub | `/inventory/products` — grid of list / barcode / import |
| Product list | `/inventory/products/list` |
| Product form | `/inventory/products/new`, `/inventory/products/:id/edit` |
| Products barcode | `/inventory/products/barcode` — generate, scan, preview, print/share; Code128 **or** self-contained product QR |
| Products import | `/inventory/products/import` |

Legacy redirects: `/inventory/count|import|reports` → stock-count paths.

Intra-module IA:

- **Inventory** (platform `AppModule`) exposes customizable service cards (order persisted): **Stock count (الجرد)** and **Products (المنتجات)**.
- **Stock count** owns counting, Excel import (quantities), and count reports via a **grid hub**.
- **Products** owns catalog CRUD + barcode hub (generate / scan / PDF label print-share) + separate Excel import (code, name, pack, price) on **Drift/SQLite**.

Capabilities:

- Hive persistence (`inventory_items`) for stock-count rows
- Drift persistence (`products`) for the product catalog
- Product barcode hub: generate, scan lookup, Code128 / product-QR preview, PDF print/share (thermal printer port reserved)
- Counting with main/sub quantities + pack-size conversion
- Status: matched / shortage / overage / not counted
- Separate Excel imports for stock count vs products
- Reports (summary, filters, search, Syncfusion chart + DataGrid)
- Excel + PDF export + share

### Accounting — implemented (foundation)

Path: `lib/modules/accounting/`

Chart of Accounts + currency rates + voucher books (sequential numbering) + standalone/integrated mode. See ADR-007 / ADR-008 / ADR-010.

### Customers — implemented

Path: `lib/modules/customers/`

| Area | Routes / entry |
| --- | --- |
| Hub | `/customers` |
| List | `/customers/list` |
| Import | `/customers/import` |
| Create / edit | `/customers/new`, `/customers/:id/edit` |
| Details | `/customers/:id` |

Capabilities:

- Drift persistence (`customers`) with soft delete + sync entity `customer`
- Unique business codes sequential from customers parent CoA code (`12210001`…) — auto / manual / external
- Excel import (`CustomerExcelImportDatasource`) — upsert by code / external id
- Optional opaque `accountId` → Accounting Account.uuid (App `CustomerAccountLinkPort`)
- Configurable **customers parent account** (CoA group, default system `1221` Customers)
- Local vs external data source + `externalId` / `upsertFromExternal`
- Does **not** auto-create Chart of Accounts rows

### Sales — implemented

Path: `lib/modules/sales/`

| Area | Routes / entry |
| --- | --- |
| Hub | `/sales` |
| List | `/sales/list` |
| Create | `/sales/create` |
| Details / edit | `/sales/:id`, `/sales/:id/edit` |

Capabilities:

- Drift persistence (`sales`, `sale_items`, `sale_payments`) + sync entity `sale`
- Local sale numbers `INV-######` fallback; primary numbering via Accounting sales voucher books
- Invoice header: date → cash/credit → sales book → number → customer/cash account → currency (FX from base product prices)
- Customer / product selection via App ports (Customers + Inventory catalog + barcode scanner)
- Item + sale discounts (fixed / %), configurable tax %, payment methods, payment status
- Lifecycle: draft → confirmed|pending → completed; cancel; duplicate
- Integrated mode: confirm → pending accounting + optional operational submit (no auto journals)
- Inventory effects via `SaleInventoryEffectPort` (NoOp until stock ledger exists)
- Customer outstanding totals foundation (`totalsForCustomer`)

### Future modules (not implemented)

Purchases, Suppliers, Expenses, Point of Sale, cross-module Reports.

## Recommended module folder layout

```text
modules/<name>/
├── <name>_module.dart
├── data/
│   ├── datasources/
│   ├── adapters/          # if Hive
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   ├── services/
│   └── usecases/
└── presentation/
    ├── pages/
    ├── widgets/
    └── providers/
```

## How to add `modules/sales/` (example)

1. Create directory tree as above.
2. Implement `SalesModule extends AppModule`.
3. Define `SalesRoutes` (e.g. `/sales`).
4. Add providers under `presentation/providers`.
5. Register in `module_bootstrap.dart`.
6. Add ARB keys (`moduleSales`, description, feature strings) EN+AR.
7. Keep Sales types out of Core and out of Inventory.
8. Update this file + `AI_CONTEXT.md` status section.

## Shared vs module widgets

- Put widgets in the module if only that module uses them.
- Put widgets in `shared/` only when multiple modules need them.
- Put generic chrome in `core/widgets/`.
