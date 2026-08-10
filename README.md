# Business Platform

Modular Flutter business platform. Inventory is the first business module — not the entire product.

## Documentation (start here)

| Audience | File |
| --- | --- |
| AI assistants (full context) | [`AI_CONTEXT.md`](AI_CONTEXT.md) |
| AI assistants (strict rules) | [`AI_RULES.md`](AI_RULES.md) |
| Humans | [`docs/`](docs/) |

Key human docs:

- [Setup](docs/setup.md)
- [Architecture](docs/architecture.md)
- [Development](docs/development.md)
- [Modules](docs/modules.md)
- [UI System](docs/ui-system.md)
- [Database](docs/database.md)
- [Localization](docs/localization.md)
- [Testing](docs/testing.md)
- [Troubleshooting](docs/troubleshooting.md)
- [ADRs](docs/adr/)

## Quick start

```bash
flutter pub get
flutter gen-l10n
flutter run
```

See [docs/setup.md](docs/setup.md) for details.

## Stack (summary)

Flutter + Riverpod + GoRouter + Hive + Material 3 / FlexColorScheme + EN/AR l10n.

Package name in `pubspec.yaml` is still `stock_count` (legacy).
