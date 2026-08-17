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
| Financial number parse / format / caret | `test/grouped_decimal_input_test.dart` |
| `AppAmountField` / `FinancialNumberField` widgets | `test/app_amount_field_test.dart` |
| Fiscal years / periods / close idempotency | `test/fiscal_year_period_test.dart` |

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

# Sync phases 3–6
flutter test \
  test/sync_health_phase3_test.dart \
  test/sync_batch_phase4_test.dart \
  test/journal_sync_phase5_test.dart \
  test/sync_observability_phase6_test.dart
```

CI runs the full Flutter suite plus backend pytest — see [`deployment.md`](deployment.md).

## Definition of Done

If tests exist for the touched area, they must be updated and pass before a change is considered complete.
