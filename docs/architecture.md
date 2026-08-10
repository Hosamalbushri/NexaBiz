# Architecture

This document describes the **actual** architecture of the Business Platform Flutter app.

Related: [`AI_CONTEXT.md`](../AI_CONTEXT.md), ADRs under [`adr/`](adr/).

## Vision

Modular Business Platform. Inventory is the first module, not the product identity.

## Top-level layout

```text
lib/
├── app/        # Composition root
├── core/       # Generic infrastructure + design system + module contract
├── modules/    # Business modules
│   └── inventory/
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
Module routes (registry)
  /inventory/...
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

## Module layer (Inventory)

Clean-ish vertical slice:

| Folder | Contents |
| --- | --- |
| `domain/` | Entities, repository contracts, use cases, calculators |
| `data/` | Hive, adapters, Excel/PDF datasources, repository impl |
| `presentation/` | Pages, widgets, Riverpod providers |
| `inventory_module.dart` | `AppModule` implementation + routes |

## Navigation model

- Platform shell routes: `/`, `/settings`
- Module routes contributed by registry (Inventory under `/inventory/...`)

## State management

Riverpod throughout. See [ADR-002](adr/ADR-002-state-management.md).

## Persistence

Hive local DB. See [ADR-004](adr/ADR-004-local-database.md) and [`database.md`](database.md).

## UI system

Material 3 + FlexColorScheme + tokens + App* widgets. See [`ui-system.md`](ui-system.md) and [ADR-003](adr/ADR-003-ui-design-system.md).
