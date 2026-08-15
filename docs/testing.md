# Testing

## Current status

Active suite under `test/` with Flutter `flutter_test`.

Accounting-focused coverage:

| Area | File |
|---|---|
| Mode / fiscal / money helpers | `test/accounting_mode_test.dart` |
| Chart of Accounts CRUD / seed / tree | `test/accounting_chart_of_accounts_test.dart` |
| Journals, sale posting, statements | `test/sales_ledger_posting_test.dart` |
| Phase 5 integrity, race token, scale, COA widget | `test/accounting_phase5_coverage_test.dart` |
| System Setup coordinator / persistence | `test/system_setup_test.dart` |

## Expectations going forward

When adding critical logic (especially domain calculators, import parsing, status math, ledger posting), add or extend tests under `test/`.

Suggested first targets for other modules:

1. `CountingCalculator`
2. `PackSizeParser`
3. `ExcelImportDatasource` with fixture bytes
4. `ReportSummary.fromItems`

## Commands

```bash
flutter test
flutter analyze

# Accounting slice
flutter test \
  test/accounting_mode_test.dart \
  test/accounting_chart_of_accounts_test.dart \
  test/sales_ledger_posting_test.dart \
  test/accounting_phase5_coverage_test.dart
```

## Definition of Done

If tests exist for the touched area, they must be updated and pass before a change is considered complete.
