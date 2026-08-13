# Architecture

This document describes the **actual** architecture of the Business Platform Flutter app.

Related: [`AI_CONTEXT.md`](../AI_CONTEXT.md), ADRs under [`adr/`](adr/) including [ADR-006](adr/ADR-006-offline-first-sync.md), [ADR-007](adr/ADR-007-accounting-chart-of-accounts.md), and [ADR-008](adr/ADR-008-accounting-operating-modes.md).

## Vision

Modular Business Platform. Inventory is the first module, not the product identity.

## Top-level layout

```text
lib/
├── app/        # Composition root
├── core/       # Generic infrastructure + design system + module contract
├── modules/    # Business modules
│   ├── inventory/
│   ├── accounting/
│   └── customers/
├── shared/     # Cross-module reusable launcher UI
└── main.dart
```

## Dependency direction

```text
Presentation → Domain ← Data   (within a module)

App → Core
App → Shared
App → Modules
Shared → Core (abstractions/widgets)
Modules → Core (+ app l10n/theme as established)
Modules ↛ other Modules
Core ↛ Modules
```

## App layer

Owns:

- `BusinessPlatformApp`
- GoRouter composition (`StatefulShellRoute` for Dashboard / Services / Reports / Settings)
- Module bootstrap (`module_bootstrap.dart`)
- Theme / breakpoints / localization
- Platform settings
- Dashboard, Services launcher, platform reports hub, Not Found
- Responsive `AppShell` (NavigationBar / Rail / side panel)
- Splash bootstrap + root exit handling

## Navigation

```text
/splash
StatefulShellRoute
  /dashboard
  /services
  /reports
  /settings
  /settings/setup
Module routes (registry)
  /inventory/...
  /accounting/...
  /customers/...
errorBuilder → NotFoundPage
```

- `/` redirects to `/dashboard`
- Modules register via `AppModule.routes`; App composes them
- Back: nested pops first; shell non-dashboard → dashboard; dashboard → exit dialog
- Do not add `go_router_builder` while routes are composed dynamically from modules

## Core layer

Owns:

- `AppModule` + `ModuleRegistry`
- Hive platform init + settings box name
- Theme/locale Riverpod providers
- Design-system widgets (`AppButton`, `AppCard`, …)

Must not contain business entities (no `InventoryItem`, no future `SalesOrder`).

Placeholder stubs (empty libraries today): `network`, `errors`, `storage`, `services`, `utils`, `extensions`.

## Shared layer

Owns Service Launcher presentation helpers:

- `ServiceCard`, `ServiceGrid`, `ServiceLauncher`

Placeholder stubs: `shared/models`, `shared/providers`.

Do not dump module-specific widgets here.

## Module layer

Clean-ish vertical slices under `lib/modules/`:

| Module | Contents |
| --- | --- |
| `inventory/` | Stock count (Hive) + products catalog (Drift) |
| `accounting/` | Chart of Accounts + currency rates + voucher books (Drift); future journals/ledger/reports |
| `customers/` | Customer master (Drift); optional opaque Account.uuid link via App port |

Each module exposes an `AppModule` implementation + routes. Modules must not import other modules.

## Navigation model

- Platform shell routes: `/`, `/settings`
- Module routes contributed by registry (Inventory under `/inventory/...`)

## State management

Riverpod throughout. See [ADR-002](adr/ADR-002-state-management.md).

## Persistence

Hive for settings, notifications, sync queue, and stock-count items; Drift/SQLite for products. See [ADR-004](adr/ADR-004-local-database.md), [ADR-005](adr/ADR-005-drift-products.md), [ADR-006](adr/ADR-006-offline-first-sync.md), and [`database.md`](database.md).

## Offline-first sync

Local database is the UI source of truth. Mutations enqueue durable `SyncOperation` rows; `SyncManager` uploads/downloads when connectivity is restored. Feature modules register `SyncEntityHandler` adapters — they do not own separate sync engines.

## Global loading overlay

Blocking user waits use `LoadingController` + `LoadingOverlayHost` (`lib/core/services/`, `lib/core/widgets/loading_overlay.dart`). Prefer `loadingControllerProvider.run(...)` so the overlay always clears after success or failure. Background sync must not use this overlay — only explicit user actions (Sync Now, import, export, …).

## UI system

Material 3 + FlexColorScheme + tokens + App* widgets. See [`ui-system.md`](ui-system.md) and [ADR-003](adr/ADR-003-ui-design-system.md).
