# ADR-008: Accounting Standalone vs Integrated Modes

## Status

Accepted — 2026-08-13  
Amended — 2026-08-14 (standalone cash + credit sale journals on save; post marks sale+journal posted)  
Amended — 2026-08-14 (JournalPostingService + fiscal closed-through; manual journal UI)

## Context

The Accounting module already provides Chart of Accounts. The platform must support two operating scenarios without rebuilding that foundation:

1. **Standalone** — the app owns local accounting master data, journals, and ledger/reports.
2. **Integrated** — the app is an operational interface beside an existing accounting/ERP system.

Operational documents (invoices, expenses, …) remain conceptually separate from journal entries: the operational sale row is not itself a ledger posting. Accountants may still review and post later for documents outside the Soft2-compatible auto-post path below. All journal writes (manual UI and sale adapter) go through `JournalPostingService`, which enforces `FiscalPeriodPolicy` against settings key `accounting_fiscal_closed_through` before calling `JournalRepository`.

## Decision

- Add `AccountingMode { standalone, integrated }` in the Accounting domain.
- Persist the mode in platform Hive settings (`SettingsKeys.accountingMode`) via `SettingsRepository`.
- Expose mode through Riverpod (`accountingModeProvider`) and a small `AccountingModePolicy`.
- Introduce vendor-agnostic `AccountingIntegrationPort` with a `NoOpAccountingIntegrationPort` default — no ERP SDK coupling.
- Add foundational types for future docs: `OperationalAccountingStatus`, `ExternalAccountingReference`.
- Settings UI: `AccountingSettingsPanel` contributed via `AccountingModule.buildSettingsSections` (platform Settings → Modules).

### Exception — standalone sales journals (Soft2-compatible)

In **standalone** mode, saving a **sales invoice** creates/updates a **local journal entry** via App `SaleLedgerPostingPort.syncSale` → `AccountingSaleLedgerAdapter` → `JournalPostingService`, with `journal.isPosted == sale.saleStatus.isPosted` (unposted invoices appear on statements as unposted/green):

**Credit (`بيع آجل`):**
- `Dr` customer CoA account (`Sale.customerAccountId`) for net total
- `Cr` sales revenue (`4100` / system `sales_revenue`) for net + discounts (gross)

**Cash (`بيع نقدي`):**
- `Dr` cash/treasury account (`Sale.cashAccountId`) for net total
- `Cr` sales revenue (`4100` / system `sales_revenue`) for net + discounts (gross)

**Discount (item + invoice):**
- `Dr` sales discounts (`5170` / system `sales_discounts`) for `itemDiscountTotal + discountAmount`
- Only added when discount > 0; keeps the entry balanced with the gross revenue credit

- Linked by `sourceType=sale` + `sourceId=sale.uuid` (re-save replaces the entry in place; no duplicate)
- **Post** (`ترحيل`) marks both the sale and journal as posted and applies inventory
- Operational document stays separate from the journal; reference is only via source fields

In **integrated** mode, post still performs operational submit only — **no** local journal.

Tax split lines (VAT output) and reverse journals beyond soft-void are out of scope for this amendment.

## Consequences

- Chart of Accounts and sync continue in both modes; journals live in Accounting Drift (`journal_entries` / `journal_lines`).
- Manual journal list/create/edit/details UI is available in the Accounting module; fiscal closed-through is configurable in Accounting settings.
- Account statements read journal lines for the selected account (posted / unposted / all). Business dates use the device local calendar day so same-day invoices are not dropped by UTC conversion.
- Future modules can branch on `AccountingModePolicy` without hard-coding ERP vendors.
- Integrated connectors register by overriding `accountingIntegrationPortProvider`.
