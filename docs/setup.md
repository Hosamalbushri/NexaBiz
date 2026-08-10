# Setup

## Clone and install

```bash
cd /path/to/untitled2
flutter pub get
flutter gen-l10n
```

## Verify toolchain

```bash
flutter doctor
flutter --version
```

Expected SDK constraint from `pubspec.yaml`:

```yaml
environment:
  sdk: ^3.12.2
```

## Run

### Android

```bash
flutter run -d android
# or a specific device id from `flutter devices`
```

### Web

```bash
flutter run -d chrome
```

## Analyze

```bash
flutter analyze
```

## Project configuration files

| File | Purpose |
| --- | --- |
| `pubspec.yaml` | Dependencies and package metadata |
| `analysis_options.yaml` | Lints (`flutter_lints`) |
| `l10n.yaml` | Localization generation |
| `.metadata` | Flutter create metadata |

## Platforms in this repository

| Platform | Present |
| --- | --- |
| Android | Yes (`android/`) |
| Web | Yes (`web/`) |
| iOS / macOS / Linux / Windows | Not present in this workspace |

## Notes

- Package name in pubspec is still `stock_count` (legacy).
- No `assets/` directory is configured.
- No `test/` directory is present yet.
- Default Flutter README still exists at repo root; prefer this `docs/` set + `AI_CONTEXT.md`.
