# Development Guide

## Prerequisites

- Flutter SDK matching project constraint (`sdk: ^3.12.2`)
- Verified in this workspace: Flutter `3.44.4`, Dart `3.12.2`
- Android and/or Chrome tooling for the platforms present in the repo

## Read first

1. [`AI_RULES.md`](../AI_RULES.md)
2. [`AI_CONTEXT.md`](../AI_CONTEXT.md)
3. This folder’s topic docs

## Common commands

```bash
flutter pub get
flutter gen-l10n
flutter analyze
dart format .
flutter run
flutter test   # only after tests exist
```

## Day-to-day workflow

1. Identify whether the change belongs to **App**, **Core**, **Shared**, or a **Module**.
2. Search for an existing widget/provider/use case before creating one.
3. Implement the smallest change.
4. Add EN + AR strings for any new UI text.
5. Run `dart format` and `flutter analyze`.
6. Update docs if architecture/behavior changed.

## Adding a module

See [`modules.md`](modules.md) and `AI_CONTEXT.md` §29.

Minimum registration point:

```text
lib/app/bootstrap/module_bootstrap.dart
```

Navigation checklist when adding a module:

1. Implement `AppModule` with `routes` + `rootRoute`
2. Register in `module_bootstrap.dart`
3. Add EN + AR launcher strings
4. Open from Services via `context.push(module.rootRoute)` (fullscreen module stack)
5. Do **not** create a second `GoRouter`

## Shell destinations (App-owned)

```text
/dashboard  /services  /reports  /settings
```

Defined in `lib/app/navigation/app_navigation_items.dart` and mounted by `app_router.dart`.

## Adding a feature inside Inventory

Typical touch points:

- Domain rule → `domain/services` or `domain/usecases`
- Persistence → `data/repositories` / datasources
- UI state → `presentation/providers`
- Screen → `presentation/pages` + widgets
- Routes → `inventory_module.dart` / `inventory_routes.dart`
- Strings → `lib/app/localization/app_en.arb` + `app_ar.arb`

## Changing UI

Prefer:

- `lib/core/widgets/app_*.dart`
- tokens in `lib/app/theme/`

Avoid inventing one-off colors/spacing.

## Changing database

See [`database.md`](database.md). Document migrations.

## Localization

See [`localization.md`](localization.md). Never hardcode user-facing strings.

## Code review checklist

Use Definition of Done in `AI_CONTEXT.md` §37.
