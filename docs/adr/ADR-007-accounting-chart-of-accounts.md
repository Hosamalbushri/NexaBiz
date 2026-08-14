# ADR-007: Accounting Chart of Accounts (Drift)

## Status

Accepted — 2026-08-12

## Context

The platform needs a reusable Accounting module. The first slice is Chart of Accounts (COA), which future journals, ledger, and financial reports will reference by stable account UUID.

## Decision

- Own a module under `lib/modules/accounting/` implementing `AppModule`.
- Persist accounts in a dedicated Drift database (`AccountingDatabase`, file `accounting_accounts`) — same technology as Inventory products, separate file to keep module boundaries clear.
- Model hierarchy with `parentId` (UUID), `level`, `isGroup` / posting distinction, `AccountType`, and domain-derived `NormalBalance`.
- Soft-delete + deactivate; protect `isSystemAccount` rows.
- Seed a default system chart once when the table is empty (local `synced`, no sync-queue flood).
- User mutations enqueue Core `SyncOperation` rows (`entityType: account`) via existing `SyncManager`.

## Default system chart (trading + VAT)

Seed catalog: `DefaultChartOfAccounts` (`system:<key>` in `description`). Existing module codes stay stable (`1211` cash, `1221` customers, `1230` inventory, `4100` sales revenue, `5100` COGS). Additive operational accounts include VAT input/output (`1250` / `2130`), suppliers group (`2111`), petty cash, sales returns/discounts, inventory adjustments, and related expense/revenue leaves. `ensureDefaultChartSeeded` inserts any newly added system seeds into existing databases without renumbering.

## Consequences

- Journal lines FK `account.uuid` (`journal_entries` / `journal_lines`, schema v6).
- Reports can aggregate by type / parent / code / hierarchy on the same table; account statement loads ledger movements from journals.
- Inventory and Accounting remain independent modules; no cross-module imports.
