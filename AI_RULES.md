# AI Rules

Read this file before modifying the project. For full context see [`AI_CONTEXT.md`](AI_CONTEXT.md) and [`docs/`](docs/).

## Project Identity

- This is a **Modular Business Platform**, not an inventory-only app.
- Pub package name is still `stock_count` (legacy); product name is **Business Platform**.
- Inventory is the **first** business module under `lib/modules/inventory/`.
- Accounting is the **second** business module under `lib/modules/accounting/` (Chart of Accounts, currency rates, voucher books; standalone/integrated operating modes via settings).
- Customers is the **third** business module under `lib/modules/customers/` (master data; optional opaque link to Account.uuid).
- Sales is the **fourth** business module under `lib/modules/sales/` (operational sales documents; ports to Customers/Inventory/Accounting).
- Reports is the **fifth** business module under `lib/modules/reports/` (PDF catalog/preview; shared kit in `lib/core/reporting/`).
- Do not redesign the app around Inventory.

## Architecture Rules

- Layers: `lib/app/`, `lib/core/`, `lib/shared/`, `lib/modules/`, `lib/main.dart`.
- Dependency direction inside a module: **Presentation → Domain → Data**.
- App wires modules; Core must **not** import modules.
- Modules must not depend on unrelated modules.
- Prefer smallest safe change; no architecture rewrites for one feature.

## Navigation Rules

- One application `GoRouter` only (`appRouterProvider`).
- Top-level shell destinations (Dashboard / Services / Reports / Settings) are App-owned via `StatefulShellRoute`.
- Modules own their route trees and register them through `AppModule.routes`.
- Do not create a second router inside a module.
- Root exit confirmation belongs to the App shell — not inside business modules.

## Module Rules

- Business logic lives in the owning module only.
- Register new modules in `lib/app/bootstrap/module_bootstrap.dart`.
- Module routes live with the module (`*Routes` + `AppModule.routes`).
- Module-specific settings live in the module and are exposed via `AppModule.buildSettingsSections` / `hasSettings` (platform Settings must not hard-import module settings widgets).
- Implement `AppModule` (`lib/core/modules/app_module.dart`).

## UI Rules

- Prefer Design System widgets in `lib/core/widgets/` (`AppButton`, `AppCard`, …).
- Prefer tokens: `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppBreakpoints`.
- Prefer `Theme.of(context).colorScheme` over raw brand colors in screens.
- No hardcoded user-facing strings — use ARB localization.
- Do not invent a parallel visual system inside a module.
- **GetWidget is not used** in this project. Do not add it without approval.
- Syncfusion is allowed for advanced reports (charts/DataGrid) in Inventory.
- PDF export uses package `pdf` (not Syncfusion PDF — dependency conflict with `excel`/`xml`).

## State Management Rules

- Use **Riverpod** (`flutter_riverpod`).
- Keep business logic out of widgets; put it in providers / domain services / use cases.
- UI reads providers and renders loading / error / empty / data states.

## Database Rules

- Platform settings: Hive box `app_settings` via `SettingsRepository`.
- Stock-count items: Hive box `inventory_items` owned by the Inventory module.
- Products catalog: Drift/SQLite via `InventoryDatabase` / `ProductRepository`.
- Chart of Accounts: Drift/SQLite via `AccountingDatabase` / `AccountRepository`.
- Currency rates + voucher books: same `AccountingDatabase` (local master data).
- Customers master: Drift/SQLite via `CustomersDatabase` / `CustomerRepository`.
- Sales documents: Drift/SQLite via `SalesDatabase` / `SaleRepository`.
- Sync queue: Hive box `sync_queue` via Core `SyncQueue` / `SyncManager`.
- UI must never open Hive boxes or Drift databases directly.
- UI must never call the remote API directly — only repositories + sync.
- Schema/adapter/migration changes require documented notes (`docs/database.md`, ADRs).

## Dependency Rules

- Do not add packages without justifying necessity and compatibility.
- Check Flutter SDK / existing packages first.
- Keep third-party UI usage localized (do not spread Syncfusion into Core).

## Coding Rules

1. Inspect existing code before changing it.
2. Prefer targeted edits over full-file rewrites.
3. Search for existing equivalents before creating new widgets/services.
4. Follow naming already used in the codebase.
5. Run `flutter analyze` after changes; format with `dart format`.
6. Update docs when architecture/behavior changes.

## Forbidden Actions

- Business logic in UI widgets
- Module-specific types in `core/`
- Circular dependencies
- Hardcoded strings / theme values when tokens exist
- Direct DB access from UI
- Massive unrelated refactors without approval
- Removing features without explicit instruction
- Silent public API breaks
- Fabricating architecture that does not exist

## Required Workflow

```text
1. Understand request
2. Inspect relevant files + architecture
3. Identify owning module
4. Check reusable components
5. Implement smallest safe change
6. Format + analyze (+ tests when present)
7. Update docs if needed
8. Summarize
```

## Completion Checklist

```text
[ ] Architecture followed
[ ] Existing components reused
[ ] No unnecessary dependencies
[ ] Localization done (EN + AR)
[ ] Loading / error / empty handled where relevant
[ ] Analyze passes
[ ] Docs updated if architecture/behavior changed
```
