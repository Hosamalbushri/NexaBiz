# ADR-008: Accounting Standalone vs Integrated Modes

## Status

Accepted — 2026-08-13

## Context

The Accounting module already provides Chart of Accounts. The platform must support two operating scenarios without rebuilding that foundation:

1. **Standalone** — the app owns local accounting master data and future ledger/reports.
2. **Integrated** — the app is an operational interface beside an existing accounting/ERP system.

Operational documents (future invoices, expenses, …) are not journal entries. Creating an operational document must not auto-create a journal entry; accountants may review and post later (locally or externally).

## Decision

- Add `AccountingMode { standalone, integrated }` in the Accounting domain.
- Persist the mode in platform Hive settings (`SettingsKeys.accountingMode`) via `SettingsRepository`.
- Expose mode through Riverpod (`accountingModeProvider`) and a small `AccountingModePolicy`.
- Introduce vendor-agnostic `AccountingIntegrationPort` with a `NoOpAccountingIntegrationPort` default — no ERP SDK coupling.
- Add foundational types for future docs: `OperationalAccountingStatus`, `ExternalAccountingReference`.
- Settings UI: `AccountingSettingsPanel` contributed via `AccountingModule.buildSettingsSections` (platform Settings → Modules).
- Do **not** implement invoices, journals, or a real ERP connector in this slice.

## Consequences

- Chart of Accounts and existing sync continue unchanged in both modes.
- Future modules can branch on `AccountingModePolicy` without hard-coding ERP vendors.
- Integrated connectors register by overriding `accountingIntegrationPortProvider`.
