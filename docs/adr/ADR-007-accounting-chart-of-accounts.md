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

## Consequences

- Journal lines can later FK `account.uuid` without redesign.
- Reports can aggregate by type / parent / code / hierarchy on the same table.
- Inventory and Accounting remain independent modules; no cross-module imports.
