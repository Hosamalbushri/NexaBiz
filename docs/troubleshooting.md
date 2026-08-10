# Troubleshooting

## `moduleRegistryProvider` UnimplementedError

Cause: App started without overriding the module registry.

Fix: ensure `main.dart` uses `moduleRegistryOverrides()` from `lib/app/bootstrap/module_bootstrap.dart`.

## Hive / inventory box crashes

Symptoms: type cast errors or open failures on `inventory_items`.

Current recovery: `InventoryHive.openBox()` deletes the corrupt box and recreates it (data loss for that box).

Mitigations:

- Avoid changing `InventoryItemAdapter` field layout carelessly
- Backup exports before schema experiments

## Localization keys missing

Run:

```bash
flutter gen-l10n
flutter analyze
```

Check both `app_en.arb` and `app_ar.arb`.

## Syncfusion PDF / xml conflicts

Do not add `syncfusion_flutter_pdf` alongside `excel` without resolving the `xml` version conflict.

Current PDF export uses the `pdf` package.

## Import fails

Check:

- File extension is `xlsx`/`xls`
- File bytes were readable (`file_picker` `withData: true`)
- Workbook is non-empty
- At least one row has code + name

Error codes: `empty_workbook`, `no_valid_rows`, `decode_failed`, `no_file`.

## Analyze noise on settings radios

`platform_settings_page.dart` may report Flutter 3.32+ deprecations for `Radio.groupValue` / `onChanged`. Functional; migrate to `RadioGroup` when touching that file.

## Platform not found

This repo currently includes **Android** and **Web** only. Running for iOS/desktop requires creating those platform folders first.

## Package name confusion

Pub name is `stock_count`; product UI title is Business Platform. This is intentional legacy naming unless/until renamed.
