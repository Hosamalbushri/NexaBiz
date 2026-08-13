# AI Project Context

> Single source of truth for AI coding assistants working on this repository.
> Concise mandatory rules: [`AI_RULES.md`](AI_RULES.md).
> Human docs: [`docs/`](docs/).

---

## 1. Project Overview

| Field | Value |
| --- | --- |
| Product name | Business Platform (`AppConstants.appName`, l10n `appTitle`) |
| Pub package name | `stock_count` (legacy name in `pubspec.yaml`) |
| Version | `0.1.0+1` |
| Type | Flutter application (modular business platform) |
| Entry point | `lib/main.dart` |
| Root widget | `BusinessPlatformApp` in `lib/app/app.dart` |
| Startup | Splash (`/splash`) → `AppBootstrap` → home shell (`/`) |
| First module | Inventory (`lib/modules/inventory/`) |
| Platforms present in repo | **Android**, **Web** |
| Platforms absent | iOS, macOS, Linux, Windows folders — **Unknown / Not configured** in this workspace |
| Assets folder | **Unknown / Not configured** (no `assets/` directory) |
| Test suite | `test/splash_and_exit_test.dart` (splash + exit dialog) |

---

## 2. Project Goals

- Provide a reusable **platform shell** for multiple independent business services.
- Keep modules isolatable so new services can be added without rewriting Core/App foundation.
- Deliver a consistent Material 3 design system and bilingual EN/AR UX.
- Ship Inventory as the first complete vertical: count, import, reports, export.

---

## 3. Product Vision

This application is a **Modular Business Platform**.

It must **not** be treated as “an inventory app.” Inventory is only the first module.

Future modules (not implemented):

- Sales
- Purchases
- Customers
- Suppliers
- Expenses
- Accounting
- Point of Sale
- Cross-module Reports
- Other business services

Adding a module must not require rewriting `core/` or unrelated modules.

---

## 4. Technology Stack

### Runtime (verified in this environment)

| Tool | Version |
| --- | --- |
| Flutter | `3.44.4` (stable) |
| Dart | `3.12.2` |
| SDK constraint (`pubspec.yaml`) | `sdk: ^3.12.2` |

### Dependencies (`pubspec.yaml`)

| Package | Role in this project |
| --- | --- |
| `flutter` / `flutter_localizations` / `intl` | UI + l10n |
| `flutter_riverpod` | State management / DI |
| `go_router` | Navigation |
| `hive` / `hive_flutter` | Local persistence |
| `excel` | Excel import/export |
| `file_picker` | Pick Excel files |
| `path_provider` | Write export files |
| `package_info_plus` | About / version in settings |
| `google_fonts` | Cairo typography |
| `flex_color_scheme` | Theme construction |
| `flutter_animate` | Subtle UI motion |
| `skeletonizer` | Skeleton loading |
| `syncfusion_flutter_charts` | Report status chart |
| `syncfusion_flutter_datagrid` | Report data grid |
| `pdf` | PDF report export |
| `share_plus` | Share exported files |
| `drift` / `drift_flutter` / `sqlite3_flutter_libs` | Products catalog SQLite |
| `barcode_widget` | Code128 barcode preview on product form |
| `mobile_scanner` | Camera barcode scan (products list + form) |

### Explicitly not present

| Item | Status |
| --- | --- |
| GetWidget | **Not configured** — do not assume it exists |
| Syncfusion PDF | **Not used** — conflicted with `excel` (`xml` versions); PDF uses `pdf` package |
| HTTP / Dio / retrofit | **Not configured** |
| Auth / Firebase | **Not configured** |
| Logging framework | **Not configured** |
| CI config in repo root | **Unknown / Not configured** |

Dev: `flutter_test`, `flutter_lints`.

---

## 5. Architecture

High-level layout:

```text
lib/
├── app/          # Composition root: theme, router, l10n, shell, settings, bootstrap
├── core/         # Generic infrastructure + design-system widgets + module contract
├── modules/      # Business modules (currently inventory only)
├── shared/       # Cross-module reusable UI (service launcher)
└── main.dart     # Bootstrap
```

### Layer responsibilities

| Layer | Responsibility |
| --- | --- |
| `app/` | Wires modules, owns platform routes (`/`, `/settings`), theme, localization generation, responsive shell |
| `core/` | `AppModule`, `ModuleRegistry`, Hive init/settings box name, DI providers for theme/locale, generic widgets |
| `modules/*` | Full vertical slices: data / domain / presentation for one business domain |
| `shared/` | Widgets genuinely shared across modules (Service Launcher cards/grid) |

Inside Inventory (and future modules), prefer:

```text
Presentation → Domain ← Data
```

UI/providers call use cases / repositories; repositories talk to datasources/Hive.

---

## 6. Project Structure

### App (`lib/app/`)

- `app.dart` — `BusinessPlatformApp`
- `bootstrap/` — `module_bootstrap.dart` (module registry), `app_bootstrap.dart` + `app_initialization.dart` (platform startup)
- `splash/` — `SplashPage` + brand widgets (`flutter_animate`)
- `exit/` — `AppExitPopScope` + `confirmAppExit` (Dashboard root back → exit dialog)
- `navigation/` — `AppNavigationItem` + top-level shell destinations
- `router/` — `GoRouter` composition + `AppRoutes` (`/splash`, `/dashboard`, `/services`, `/reports`, `/settings`)
- `shell/app_shell.dart` — responsive chrome for StatefulShellRoute (`platform_shell.dart` re-exports)
- `theme/` — tokens + FlexColorScheme themes + component themes
- `localization/` — ARB + generated `AppLocalizations`
- `settings/` — theme/locale persistence UI + repository
- `presentation/pages/` — dashboard, services launcher, platform reports, not found
- `constants/app_constants.dart`

### Core (`lib/core/`)

- `modules/` — `AppModule`, `ModuleRegistry`, providers
- `database/` — `HiveInitializer`, `HiveBoxes.settings`
- `di/app_providers.dart` — `themeModeProvider`, `localeProvider`
- `widgets/` — design-system widgets (+ some legacy widgets still present)
- Stub libraries (mostly empty placeholders): `errors/`, `network/`, `storage/`, `services/`, `utils/`, `extensions/`

### Shared (`lib/shared/`)

- `widgets/service_card.dart`, `service_grid.dart`, `service_launcher.dart`
- `models/models.dart`, `providers/providers.dart` — placeholder libraries

### Inventory module (`lib/modules/inventory/`)

Platform module (`id: inventory`). Intra-module services: **Stock count** (`/inventory/stock-count/...`) and **Products** (`/inventory/products/...`).

```text
inventory/
├── inventory_module.dart
├── data/
│   ├── adapters/
│   ├── database/      # Drift InventoryDatabase + products table
│   ├── datasources/   # stock-count + products excel import (separate), export, pdf
│   ├── repositories/
│   └── inventory_hive.dart
├── domain/
│   ├── entities/      # InventoryItem + Product
│   ├── models/
│   ├── repositories/
│   ├── services/
│   └── usecases/
└── presentation/
    ├── pages/         # stock_count_home, products_home, list/form/import/barcode, barcode scanner
    ├── widgets/
    └── providers/
```

---

## 7. Architecture Rules

1. Core must not import `modules/` or business entities.
2. Modules must not import other modules.
3. App may import Core, Shared, and Modules (composition root).
4. Shared must not import Modules.
5. Presentation must not open Hive boxes, Drift databases, or parse Excel directly.
6. Prefer extending existing patterns over inventing new ones.
7. Stub folders (`network`, `errors`, …) are placeholders — do not invent APIs there unless implementing for real.

---

## 8. Modular Architecture

Contract: `AppModule` in `lib/core/modules/app_module.dart`.

Each module provides:

- `id`, `nameKey`, `icon`, `rootRoute`, `isEnabled`
- `label` / `description` via `BuildContext` + l10n
- `routes` (`List<RouteBase>`)
- optional `providerOverrides`

Registry: `ModuleRegistry` — App overrides `moduleRegistryProvider` in `module_bootstrap.dart`.

Launcher shows `enabledModules` only. Router mounts `registry.routes`.

---

## 9. Module Development Rules

- Keep all business types inside the module.
- Own Hive adapters/boxes inside the module data layer.
- Own routes under a module root path (e.g. `/inventory/...`).
- Register the module only in App bootstrap.
- Add EN + AR strings for every new user-facing text.
- Prefer Core design-system widgets for chrome; module widgets for domain UI.

---

## 10. Dependency Rules

Allowed import directions:

```text
main.dart → app, core
app → core, shared, modules
shared → core (module contract / generic widgets)
modules/* → core (generic only), app localization/theme/constants as currently done
modules/A ↛ modules/B
core ↛ modules, shared business widgets that pull modules
```

**Note (current reality):** Inventory presentation imports `lib/app/localization` and `lib/app/theme` / constants. That is the established pattern today. Prefer continuing this pattern rather than moving l10n into Core unless a deliberate refactor is requested.

Avoid circular imports.

---

## 11. State Management

- Library: **Riverpod** (`flutter_riverpod` ^2.6.1).
- Bootstrap: `ProviderContainer` + `UncontrolledProviderScope` in `main.dart`.
- Common patterns in Inventory:
  - `Provider` for repositories / datasources / use cases
  - `StreamProvider` for watching items
  - `StateProvider` for ephemeral UI state (selected item, search query, filters)
  - `StateNotifier` / `StateNotifierProvider` for import + save + export flows
- AsyncValue used for loading/error on save/export.
- UI must not embed counting math — use `CountingCalculator` / providers.

`AsyncNotifier` / code-gen Riverpod: **not used** currently.

---

## 12. Navigation

- Library: **GoRouter** (^16).
- Provider: `appRouterProvider` in `lib/app/router/app_router.dart`.
- Startup: `/splash` → `AppBootstrap` → `context.go('/dashboard')` (splash not kept in stack).
- Main shell: outer `ShellRoute` + `AppShell` chrome wraps:
  - `StatefulShellRoute.indexedStack` — `/dashboard`, `/services`, `/reports`, `/settings`
  - Module routes from registry (e.g. `/inventory/...`)
- Shell chrome (mobile bottom nav / tablet rail / desktop side panel) is shown **only** on primary shell tabs (`/dashboard`, `/services`, `/reports`, `/settings`). Module pages hide chrome and use their own back navigation.
- Responsive chrome: mobile `BottomAppBar` (`CustomBottomNav` + rounded-square `AutomaticNotchedShape`) with center-docked `QuickActionsFab`, tablet `NavigationRail` (leading `+`), desktop side panel (tonal add).
- Quick actions sheet: user-pinned shortcuts (create product, scan barcode, inventory routes) with customize + Hive persistence (`quick_action_ids`).
- `/` redirects to `/dashboard`.
- Module routes (inside shell chrome), Inventory:
  - `/inventory` — inventory hub (customizable/reorderable service cards; Stock count + Products)
  - `/inventory/stock-count` — stock-count hub (grid: count / import / reports)
  - `/inventory/stock-count/count` (+ `/details`)
  - `/inventory/stock-count/import`
  - `/inventory/stock-count/reports`
  - `/inventory/products` — products hub (list / barcode / import)
  - `/inventory/products/list`, `/new`, `/barcode`, `/:id/edit`, `/import`
  - Legacy `/inventory/count|import|reports` redirect into stock-count
- Module paths leave bottom-nav tabs unselected (Services is active only on `/services`).
- Exit confirmation: system Back at **Dashboard** root only (`AppExitPopScope`); other shell branches return to Dashboard; module stacks pop normally.
- Unknown routes: `errorBuilder` → `NotFoundPage`.
- Typed paths: `AppRoutes` + module `*Routes` helpers (no `go_router_builder` — dynamic `AppModule.routes` composition).
- Auth redirects: **Not configured** (router ready for future `redirect` rules).

Navigation helpers: `context.go`, `context.push`, `context.pop`.

---

## 13. Database

| Concern | Implementation |
| --- | --- |
| Engines | Hive (settings + stock-count items) + Drift/SQLite (products) |
| Init | `HiveInitializer.initialize()` via `AppBootstrap`; Drift `InventoryDatabase` lazy via providers |
| Platform box | `app_settings` (`HiveBoxes.settings`) |
| Inventory box | `inventory_items` (`InventoryHive.boxName`) — stock-count rows |
| Inventory adapter | `InventoryItemAdapter` typeId `0` |
| Products DB | Drift table `products` (`item_code`, `name`, `barcode?`, `pack_size`, `price`, timestamps); barcode generate + Code128 preview + camera scan lookup |
| Migrations | Hive: no formal system (corrupt box deleted). Drift: `schemaVersion` + `MigrationStrategy` |
| Transactions | Hive put/clear/replaceAll; Drift batch upsert for products import |
| DAOs | Not used; datasources + repository impl |

Rule: UI never accesses Hive or Drift directly. Stock-count import and products import stay separate.

See ADR-004 (Hive) and ADR-005 (Drift products).

`main.dart` only ensures bindings + module registry overrides; theme/locale load inside bootstrap.

---

## 14. Storage

- Settings persistence: `SettingsRepository` (theme mode, locale).
- Export files written under application documents directory via `path_provider`.
- Generic `core/storage/storage.dart`: placeholder library only.

---

## 15. Network Layer

`lib/core/network/network.dart` is a placeholder.

**Status: Unknown / Not configured** — no HTTP client, no API base URL, no remote sync.

---

## 16. Dependency Injection

- Riverpod providers are the DI mechanism.
- Module registry must be overridden at startup (`moduleRegistryOverrides()`).
- Inventory wires its own providers in `presentation/providers/inventory_providers.dart`.
- No `get_it` / injectable.

---

## 17. UI/UX Design System

Philosophy: consistent Material 3 business UI; modules consume shared widgets/tokens.

Libraries in use:

| Library | Responsibility |
| --- | --- |
| Material 3 | Foundation |
| FlexColorScheme | Theme generation |
| Google Fonts (Cairo) | Typography EN/AR |
| Flutter Animate | Light enter animations (e.g. `AppCard`) |
| Skeletonizer | Skeleton list loading via `AppLoading` |
| Syncfusion Charts/DataGrid | Advanced Inventory reports |
| GetWidget | **Not used** |

### Preferred Core widgets (`lib/core/widgets/`)

Present and preferred:

- `AppButton`, `AppCard`, `AppTextField`, `AppSearchBar`
- `AppDialog` (`showAppDialog`), `AppBottomSheet` (`showAppBottomSheet`)
- `AppStatusBadge`, `AppLoading`, `AppEmptyState`, `AppErrorState`
- `AppSnackbar` (`showAppSnackBar`)
- `CustomAppBar`, `StatCard`

Also present (legacy / secondary — prefer App* when adding new UI):

- `AppTopBar`, `CustomBottomNav`, `EmptyStateWidget`, `ConfirmationDialog`

**Not present:** `AppDataTable` — reports use Syncfusion DataGrid inside the Inventory module.

---

## 18. Theme System

- `AppTheme.light()` / `AppTheme.dark()` in `lib/app/theme/app_theme.dart`
- Tokens:
  - `AppColors` — brand + semantic
  - `AppTypography` — Cairo text theme
  - `AppSpacing` — 4/8/12/16/24/32/40/48
  - `AppRadius` — xs→xl + pill
  - `AppShadows`
  - `AppBreakpoints` — mobile `<600`, tablet `<900`, desktop `≥900`
- Component themes under `lib/app/theme/components/`
- Runtime theme mode via `themeModeProvider` + settings persistence

---

## 19. Responsive Design

- `AppShell`:
  - Mobile: `NavigationBar`
  - Tablet: `NavigationRail`
  - Desktop: side panel (~260px)
- Service launcher / report summary grids adapt column count by width.
- Module pages are generally scrollable single-column with responsive grids where needed.

---

## 20. Localization

| Item | Value |
| --- | --- |
| Config | `l10n.yaml` |
| ARB dir | `lib/app/localization/` |
| Template | `app_en.arb` |
| Locales | English (`en`), Arabic (`ar`) |
| Generated | `app_localizations*.dart` |
| RTL | Supported via Flutter + Arabic locale |
| Access | `AppLocalizations.of(context)` |

Rule: never hardcode user-facing strings.

---

## 21. Error Handling

Centralized error taxonomy in Core: **Unknown / Not configured** (`core/errors/errors.dart` is a stub).

Current practice:

- Import: `ImportValidationException` codes mapped to l10n in UI
- Save/export: catch → `AsyncError` / snackbars / error banners
- Lists: `AppErrorState` with retry invalidating providers

Desired direction when expanding:

```text
Data → Domain → Presentation → UI (localized message)
```

Differentiate validation / file / storage / unexpected errors with stable codes when adding new flows.

---

## 22. Logging

**Unknown / Not configured** — no shared logger package or `AppLogger`.

Do not sprinkle `print` in production paths; if logging is required, propose a Core utility first.

---

## 23. Performance

Implemented / expected practices:

- Debounced inventory search (~250ms)
- Excel parse via `compute` isolate (`excel_import_isolate.dart`)
- Syncfusion grid for denser report tables
- Prefer `ListView` / grid `shrinkWrap` carefully; avoid rebuilding entire trees
- Target responsiveness with large local inventories (thousands of items)

Not implemented yet: pagination, Hive indexing strategy docs, background isolates for export.

---

## 24. Security

**Unknown / Not configured** beyond local-device Hive storage.

No auth, encryption-at-rest, or remote secrets management found.

Treat export files as potentially sensitive business data when sharing.

---

## 25. Testing

- `flutter_test` is a dev dependency.
- Present: `test/splash_and_exit_test.dart`, `test/navigation_shell_test.dart`.
- Definition of Done still requires adding/updating tests when introducing critical domain logic.

Commands:

```bash
flutter test
```

---

## 26. Naming Conventions

| Kind | Convention | Example |
| --- | --- | --- |
| Files | `snake_case.dart` | `inventory_home_page.dart` |
| Classes | `PascalCase` | `InventoryHomePage` |
| Members | `camelCase` | `itemCode` |
| Providers | `xxxProvider` | `inventoryItemsProvider` |
| Repositories | `XxxRepository` / `XxxRepositoryImpl` | `InventoryRepository` |
| Use cases | Verb phrase class | `SaveInventoryCount` |
| Entities | Domain nouns | `InventoryItem` |
| Pages | `XxxPage` | `InventoryReportsPage` |
| Routes class | `XxxRoutes` | `InventoryRoutes` |
| Module id | lowercase slug | `inventory` |

---

## 27. Code Style

- Analyzer: `analysis_options.yaml` includes `package:flutter_lints/flutter.yaml`
- Prefer existing project patterns (Riverpod 2.x `StateNotifier`, sealed result classes)
- Format with `dart format`
- Analyze with `flutter analyze`

---

## 28. Git Rules

Project-specific branch/PR policy: **Unknown / Not configured** in-repo.

General expectations for AI:

- Do not commit unless the user asks
- Do not force-push or rewrite history unless explicitly requested
- Do not commit secrets

---

## 29. Adding a New Module

Mandatory workflow:

```text
1. Create lib/modules/<name>/
2. Create <name>_module.dart implementing AppModule
3. Create data / domain / presentation layers as needed
4. Add providers
5. Add routes on the module
6. Register in lib/app/bootstrap/module_bootstrap.dart
7. Add EN + AR localization keys
8. Add tests (when suite exists)
9. Update docs (modules.md, AI_CONTEXT status, ADR if architectural)
```

### Concrete example: Sales (implemented)

```text
lib/modules/sales/
├── sales_module.dart
├── data/
├── domain/
└── presentation/
```

Registered in `module_bootstrap.dart` with App adapters for Customers, Inventory scan, and Accounting bridge. See ADR-011.

---

## 30. Adding a New Feature

1. Identify owning module (or App/Core if platform-level).
2. Search for existing use case / widget / provider.
3. Add domain logic first when business rules are involved.
4. Wire data if persistence/IO required.
5. Expose via providers.
6. Build UI with App* widgets + l10n.
7. Analyze + update docs if public behavior changes.

---

## 31. Modifying an Existing Feature

1. Read current implementation end-to-end.
2. Change the smallest surface area.
3. Preserve public routes/provider names unless a breaking change is requested.
4. Verify EN/AR strings still make sense.
5. Check related export/import/report paths for Inventory.

---

## 32. Removing a Feature

- Requires explicit user instruction.
- Remove routes, providers, UI, l10n keys, and docs references together.
- Do not leave dead module registrations.

---

## 33. Database Change Rules

- Prefer additive fields with safe adapter defaults.
- Document migration in `docs/database.md` and an ADR if significant.
- Inventory typeId `0` adapter changes can wipe/corrupt data; handle carefully (current fallback deletes box).
- Never change box names casually.

---

## 34. UI Change Rules

- Prefer tokens and App* widgets.
- Keep Inventory report Syncfusion usage inside the module.
- Match Cairo typography; do not introduce a second font stack without approval.
- Verify mobile + tablet shell behavior for platform pages.
- Verify RTL with Arabic locale for new layouts.

---

## 35. AI Coding Rules

### AI DEVELOPMENT RULES

1. Always inspect existing code before modifying.
2. Never rewrite an entire file when a targeted edit is enough.
3. Never create duplicate functionality — search first.
4. Always follow existing architecture.
5. Do not move business logic into UI.
6. Do not place module-specific logic in Core.
7. Do not create unnecessary abstractions.
8. Reuse existing components.
9. Do not introduce a new dependency without explaining necessity.
10. Before adding a package: check Flutter SDK, existing packages, and compatibility.
11. Do not modify unrelated files.
12. Do not silently change public APIs.
13. Do not remove existing functionality without explicit instruction.
14. Do not change database schemas without documenting migration.
15. Do not hardcode localized strings.
16. Do not hardcode colors/spacing when Design System tokens exist.
17. Do not use deprecated Flutter APIs.
18. Run formatting and static analysis after changes.
19. Run relevant tests after changes (when present).
20. Update documentation when architecture or behavior changes.

---

## 36. Forbidden Practices

# FORBIDDEN PRACTICES

- Massive refactoring without approval
- Rewriting unrelated files
- Duplicate widgets/services
- Business logic inside widgets
- Database access inside UI
- Hardcoded strings
- Hardcoded theme values bypassing tokens
- Circular dependencies
- Global mutable state without justification
- Unnecessary dependencies
- Deprecated APIs
- Ignoring modular boundaries
- Removing functionality without permission
- Changing Hive schemas without migration notes
- Treating the app as Inventory-only
- Adding GetWidget (or other UI kits) without explicit approval
- Putting Sales/Customers entities into Core

---

## 37. Definition of Done

```text
[ ] Architecture followed
[ ] Existing components reused
[ ] No unnecessary dependencies
[ ] Localization completed (EN + AR)
[ ] RTL verified if relevant
[ ] Loading state implemented where async
[ ] Error state implemented where async
[ ] Empty state implemented where lists can be empty
[ ] Validation implemented where inputs exist
[ ] Tests added/updated when applicable
[ ] Formatting completed
[ ] Static analysis passes
[ ] Documentation updated if necessary
```

---

## 38. Current Project Status

### Platform

| Area | Status |
| --- | --- |
| Modular registry + launcher | Implemented |
| Theme + design tokens | Implemented |
| App* design-system widgets | Implemented |
| Responsive shell | Implemented |
| Settings (theme/locale/about/reset) | Implemented |
| Localization EN/AR | Implemented |
| Splash + AppBootstrap | Implemented |
| StatefulShellRoute (Dashboard/Services/Reports/Settings) | Implemented |
| Root exit confirmation (`AppExitPopScope`) | Implemented |
| Network / Auth | Not configured |
| Automated tests | Partial (`test/splash_and_exit_test.dart`, `test/navigation_shell_test.dart`) |
| Assets pipeline | Not configured |

### Modules

| Module | Status |
| --- | --- |
| Inventory | **Implemented** (home, count/search, import, reports, Excel+PDF export) |
| Sales | **Implemented** (create/list/details, ports to Customers/Inventory/Accounting) |
| Purchases | Future |
| Customers | **Implemented** |
| Suppliers | Future |
| Expenses | Future |
| Accounting | **Implemented** (CoA, rates, voucher books, modes) |
| Point of Sale | Future |

### Inventory capabilities (present)

- Item persistence (Hive stock-count + Drift products)
- Products catalog CRUD + separate Excel import
- Product barcode generate / Code128 preview / self-contained product QR / camera scan lookup
- Products barcode hub page (PDF label print/share for Code128 or product QR; thermal port reserved)
- Search + counting (main/sub qty, pack size, difference, status)
- Excel import with validation + isolate parsing + progress
- Reports: summary cards, filters/tabs, search, Syncfusion chart + DataGrid
- Export Excel + PDF + share

---

## 39. Future Roadmap

Non-binding product direction (not scheduled in code):

1. Additional business modules (Sales first candidate)
2. Formal Core error/logging packages
3. Test suite (unit for calculators/import; widget/golden optional)
4. Stronger Hive migrations / migrate stock-count to Drift
5. Link stock-count lines to products by item_code / product id
5. Optional remote sync / network layer when product requires it
6. Broader platform targets (iOS/desktop) if added to the repo
7. Replace remaining legacy widgets with App* equivalents over time

---

## Inventory Import / Export (quick reference)

### Import

- Formats: `.xlsx`, `.xls` via `file_picker`
- Parser: `ExcelImportDatasource` on isolate via `compute`
- Header aliases include EN/AR for code, name, main qty, sub qty, barcode, pack size
- Preferred quantity columns: main + sub (legacy single system quantity still accepted)
- Missing headers fall back to column indexes: code, name, main, sub
- Invalid/empty rows ignored; duplicate codes last-write wins (counted)
- Validation failures: `empty_workbook`, `no_valid_rows`, `decode_failed`
- Progress labels: parsing → saving

### Export

- Excel: `ExcelExportDatasource` → app documents path
- PDF: `PdfExportDatasource` (`pdf` package)
- UI: reports AppBar → bottom sheet choose Excel/PDF → optional share

---

## AI Workflow (mandatory)

```text
1. Understand the request
2. Inspect relevant files
3. Inspect architecture
4. Identify affected module
5. Check existing reusable components
6. Identify dependencies
7. Propose implementation (internally)
8. Implement the smallest safe change
9. Format code
10. Run static analysis
11. Run relevant tests (if any)
12. Review for regressions
13. Update documentation if required
14. Summarize changes
```

Before coding, answer internally:

```text
What module owns this?
What existing code already handles this?
Can something be reused?
Cross-module impact?
DB / routes / l10n / tests / docs needed?
```
