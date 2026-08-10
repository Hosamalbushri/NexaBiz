# Testing

## Current status

**Unknown / Not configured** as an active suite.

Findings:

- `flutter_test` is listed under `dev_dependencies`
- No `test/` directory exists in this workspace
- No widget/unit/integration tests were found

## Expectations going forward

When adding critical logic (especially domain calculators, import parsing, status math), add tests under:

```text
test/
├── modules/inventory/...
└── ...
```

Suggested first targets:

1. `CountingCalculator`
2. `PackSizeParser`
3. `ExcelImportDatasource` with fixture bytes
4. `ReportSummary.fromItems`

## Commands

```bash
flutter test
flutter analyze
```

## Definition of Done

If tests exist for the touched area, they must be updated and pass before a change is considered complete.
