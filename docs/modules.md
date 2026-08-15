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
  SystemSetupModule(),
  InventoryModule(),
  AccountingModule(),
  CustomersModule(),
  SalesModule(),
  ReportsModule(),
]);
```

`moduleRegistryProvider` throws if not overridden — App bootstrap is mandatory.

Launcher grids use `AppModule.showInLauncher` (defaults to `isEnabled`). Routes come from every `isEnabled` module.

## Current modules

### System Setup — implemented

Path: `lib/modules/system_setup/`

First-launch / resume initialization (not a duplicate of Settings). Shown on the service launcher as **Settings** / «الإعدادات». After initialization, hosts the **module settings hub** (company + Accounting/Customers panels via `AppModule.buildSettingsSections`). Wizard route `/system-setup` is outside `AppShell`. Splash gates on versioned Hive setup state. Base currency is chosen once and locked. See [ADR-009](adr/ADR-009-system-setup.md).

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

Chart of Accounts + currency rates + voucher books + local journals. Operating mode is fixed local accounting (see ADR-008).

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
- **Auto-link** (default on): create/reuse posting CoA account under parent on save when account empty
- Configurable **customers parent account** (CoA group, default system `1221` Customers) + settings hub `/customers/settings`
- Local vs external data source + `externalId` / `upsertFromExternal`

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
- Lifecycle: unposted → posted; cancel (void journal + soft-delete); duplicate
- Integrated mode: post → operational submit (no local journals)
- Standalone cash/credit save: App `SaleLedgerPostingPort.syncSale` upserts journal with `isPosted` matching sale status (Dr customer or cash for net; Dr `5170` for discounts; Cr `4100` for gross); post marks both sale+journal posted; account statement backfills missing sale journals for the selected account
- Inventory effects via `SaleInventoryEffectPort` (NoOp until stock ledger exists)
- Customer outstanding totals foundation (`totalsForCustomer`)

### Reports — implemented (foundation)

Path: `lib/modules/reports/` + shared kit `lib/core/reporting/`

| Area | Routes / entry |
| --- | --- |
| Catalog | `/module-reports` |
| Sales by period | `/module-reports/sales-period` |
| PDF preview | `/module-reports/preview` |
| Platform hub | `/reports` → Business PDF reports |

Capabilities:

- Generic `ReportDefinition` + `ReportRunner` (no DB access in PDF layer)
- `PdfPreview` + print/share via `ReportFileActions`
- Sales period report via App `SalesPeriodReportDataAdapter` → `SaleRepository.searchListPaged`
- Account statement via App `AccountStatementReportDataAdapter` → COA + `JournalRepository` movements
- See ADR-012

### Future modules (not implemented)

Purchases, Suppliers, Expenses, Point of Sale.

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
