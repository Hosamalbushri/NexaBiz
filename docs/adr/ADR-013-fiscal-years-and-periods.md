# ADR-013: Fiscal Years and Accounting Periods

## Status

Accepted — 2026-08-17

## Context

Ledger mutations were gated by a single settings value `accounting_fiscal_closed_through` ([FiscalPeriodPolicy](../../lib/modules/accounting/domain/services/fiscal_period_policy.dart)). That model cannot express open/closed monthly periods, closing workflows, or FX revaluation configuration.

Journal lines now store `debit`/`credit` plus **base carrying amounts** (`exchange_rate_to_base`, `base_debit`, `base_credit`) and dated rates live in `currency_rate_history`, enabling period-end FX revaluation.

## Decision

1. Add Drift tables `fiscal_years`, `accounting_periods`, `period_closing_records` (schema v10) in the existing Accounting database; schema **v11** adds journal base columns + `currency_rate_history`.
2. Newly generated periods default to **closed**. Posting requires status `open` or `reopened`.
3. Central enforcement remains in [JournalPostingService](../../lib/modules/accounting/domain/services/journal_posting_service.dart) via async [AccountingPeriodValidator](../../lib/modules/accounting/domain/services/accounting_period_validator.dart) (covers manual journals, sales, and R&P adapters).
4. Compatibility: if **no** fiscal year rows exist, fall back to legacy `closedThrough`.
5. Period close is transactional and idempotent (unique completed closing record per period).
6. When FX is enabled on the fiscal year, period close runs [FxRevaluationService](../../lib/modules/accounting/domain/services/fx_revaluation_service.dart) for asset/liability foreign positions and posts a `period_fx` journal to `fx_gain` / `fx_loss`.
7. Currency exchange vouchers may realize FX differences to the same gain/loss accounts.
8. Fiscal year / period state is **local-only** in v1 (no sync handlers). Open/close are state machines and must not use naive last-write-wins.

## Consequences

- Installs without fiscal years behave as before.
- After creating a fiscal year, users must explicitly open periods before posting in those date ranges.
- ADR-008 fiscal closed-through settings remain as a legacy escape hatch and settings UI note.
- Future work: buy/sell rates; CRDT/state-machine sync for period status; year-end P&L close.
