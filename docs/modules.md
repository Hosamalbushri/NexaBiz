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
| Hub | `/inventory` |
| Count | `/inventory/count` |
| Search | `/inventory/count/search` |
| Import | `/inventory/import` |
| Reports | `/inventory/reports` |

Capabilities:

- Hive persistence (`inventory_items`)
- Counting with main/sub quantities + pack-size conversion
- Status: matched / shortage / overage / not counted
- Excel import (isolate + validation + progress)
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
