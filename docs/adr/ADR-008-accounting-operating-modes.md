# ADR-008: Accounting Operating Mode (Local Default)

## Status

Accepted — 2026-08-13  
Amended — 2026-08-14 (standalone cash + credit sale journals on save; post marks sale+journal posted)  
Amended — 2026-08-14 (JournalPostingService + fiscal closed-through; manual journal UI)  
**Superseded in part — 2026-08-15:** dual standalone/integrated **user switch removed**. The product always runs as **local accounting** (former standalone).

## Context

The Accounting module provides Chart of Accounts, journals, and reports. A dual mode (local vs ERP-integrated) existed as a settings/wizard choice. Integrated ERP connectors were never productized; the switch added complexity without value.

## Decision

1. **Single operating mode:** local ownership of CoA + journals (ex-standalone).
2. Remove Accounting mode radios from settings and the dual-choice setup step.
3. Keep `AccountingMode` / `AccountingModePolicy` as fixed local policy helpers for readability.
4. `SaleAccountingBridgePort.isIntegratedMode` is always `false`; sales always create local journals via `SaleLedgerPostingPort`.
5. `AccountingIntegrationPort` remains a NoOp placeholder for a future connector, not a user-facing mode.

### Sales journals (Soft2-compatible)

Saving a **sales invoice** creates/updates a **local journal entry** via App `SaleLedgerPostingPort.syncSale` → `AccountingSaleLedgerAdapter` → `JournalPostingService`, with `journal.isPosted == sale.saleStatus.isPosted`:

**Credit (`بيع آجل`):**
- `Dr` customer CoA account (`Sale.customerAccountId`) for net total
- `Cr` sales revenue (`4100` / system `sales_revenue`) for net + discounts (gross)

**Cash (`بيع نقدي`):**
- `Dr` cash/treasury account (`Sale.cashAccountId`) for net total
- `Cr` sales revenue (`4100` / system `sales_revenue`) for net + discounts (gross)

**Discount (item + invoice):**
- `Dr` sales discounts (`5170` / system `sales_discounts`) when discount > 0

- Linked by `sourceType=sale` + `sourceId=sale.uuid`
- **Post** marks sale + journal posted and applies inventory

## Consequences

- Chart of Accounts, sync, journals, and account statements remain local.
- Setup wizard “welcome” step confirms local accounting only (no ERP choice).
- Re-introducing an ERP mode would require a new ADR and a real connector, not a settings toggle alone.
