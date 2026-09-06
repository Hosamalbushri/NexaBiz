# RE-09 — OFFLINE / CACHE / SYNC REPORTING

## 1. Offline Reporting Data Policy

NexaBiz ERP operates on an **Offline-First Architecture**. All accounting and reporting query adapters read directly from local Drift sqlite database tables (`journal_entries`, `journal_lines`, `accounts`, `sales_invoices`, `payment_receipts`, etc.).

### Core Principles Enforced
1. **Authoritative Local Data**: Reports execute read-only queries against local Drift tables representing posted transactions stored on device.
2. **Zero In-Memory Stale Calculations**: Reports do not cache derived financial figures across database mutations. Each report request queries current table states.
3. **No Silent Data Mixing**: Data ports filter strictly on company boundaries (`companyId`) and posting status (`isPosted`). Partial sync buffers do not mix unposted offline drafts with posted ledger lines unless explicitly requested (`PostingScope.all`).
4. **Read-Only Guarantees**: Report data ports (`GeneralLedgerReportDataAdapter`, `TrialBalanceReportDataAdapter`, `BalanceSheetReportDataAdapter`, etc.) contain zero update/delete SQL statements and zero domain mutation calls.

---

## 2. Synchronization & Data Freshness

- **Sync Listener Auto-Refresh**: Riverpod providers (`generalLedgerReportDataPortProvider`, `trialBalanceReportDataPortProvider`, etc.) subscribe to the underlying database watch streams and invalidation triggers.
- **Sync Trigger Propagation**: When background sync pulls remote transactions into local Drift tables, Riverpod invalidates active report state, causing on-screen reports to automatically refresh with the latest authoritative accounting data.
