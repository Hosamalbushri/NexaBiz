# Modules

## Module contract

Every business module implements `AppModule`:

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

## Registration

Modules are registered only in:

```text
lib/app/bootstrap/module_bootstrap.dart
```

Current registry:

```dart
ModuleRegistry(const [
  InventoryModule(),
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
| Products barcode | `/inventory/products/barcode` — generate, scan, preview, print/share |
| Products import | `/inventory/products/import` |

Legacy redirects: `/inventory/count|import|reports` → stock-count paths.

Intra-module IA:

- **Inventory** (platform `AppModule`) exposes customizable service cards (order persisted): **Stock count (الجرد)** and **Products (المنتجات)**.
- **Stock count** owns counting, Excel import (quantities), and count reports via a **grid hub**.
- **Products** owns catalog CRUD + barcode hub (generate / scan / PDF label print-share) + separate Excel import (code, name, pack, price) on **Drift/SQLite**.

Capabilities:

- Hive persistence (`inventory_items`) for stock-count rows
- Drift persistence (`products`) for the product catalog
- Product barcode hub: generate, scan lookup, Code128 preview, PDF print/share (thermal printer port reserved)
- Counting with main/sub quantities + pack-size conversion
- Status: matched / shortage / overage / not counted
- Separate Excel imports for stock count vs products
- Reports (summary, filters, search, Syncfusion chart + DataGrid)
- Excel + PDF export + share

### Future modules (not implemented)

Sales, Purchases, Customers, Suppliers, Expenses, Accounting, Point of Sale, cross-module Reports.

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
2. Implement `SalesModule implements AppModule`.
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
