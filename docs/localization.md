# Localization

## Supported languages

| Locale | File |
| --- | --- |
| English (`en`) | `lib/app/localization/app_en.arb` |
| Arabic (`ar`) | `lib/app/localization/app_ar.arb` |

RTL is handled by Flutter when locale is Arabic.

## Configuration

`l10n.yaml`:

```yaml
arb-dir: lib/app/localization
output-dir: lib/app/localization
output-localization-file: app_localizations.dart
template-arb-file: app_en.arb
nullable-getter: false
```

Untranslated messages report:

`lib/app/localization/untranslated_messages.txt`

## Usage

```dart
final l10n = AppLocalizations.of(context);
Text(l10n.reportsTitle);
```

Supported locales are exposed via `AppLocalizations.supportedLocales`.

Locale preference is persisted by `SettingsRepository` and applied through `localeProvider` in `BusinessPlatformApp`.

## Naming conventions

- Keys: `lowerCamelCase`
- Feature prefixes optional but consistent (`importSuccess`, `moduleInventory`)
- Parameterized messages use ARB placeholders (e.g. `importedItemsCount`)

## Rules

1. Never hardcode user-facing strings in widgets.
2. Always add **both** EN and AR entries.
3. Run `flutter gen-l10n` after ARB edits (or rely on build-time generation).
4. Keep analytics/module keys stable (`nameKey` on `AppModule`).

## Access pattern note

Modules currently import app localization from `lib/app/localization/`. Keep this consistency unless a dedicated refactor moves l10n.
