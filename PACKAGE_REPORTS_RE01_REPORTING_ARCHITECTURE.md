# RE-01 — NexaBiz ERP Reporting Architecture & Read Models

## Overview
This document establishes the architecture for the **NexaBiz ERP Reporting Engine**. 

Reports in NexaBiz are strictly **read-side functionality**. They perform zero business logic or domain mutations and serve as optimized read views over domain source-of-truth repositories.

---

## 1. Domain Source-of-Truth Mapping

| ERP Domain | Primary Authority | Read-Side Data Port / Adapter |
| :--- | :--- | :--- |
| **Accounting** | `JournalRepository`, `AccountRepository` | `JournalBookReportDataPort` (`JournalBookReportDataAdapter`), `TrialBalanceReportDataPort` (`TrialBalanceReportDataAdapter`), `AccountStatementReportDataPort` (`AccountStatementReportDataAdapter`) |
| **Sales** | `SalesRepository` | `SalesPeriodReportDataPort` (`SalesPeriodReportDataAdapter`) |
| **Inventory** | `InventoryDatabase` | `ProductStockMovementReportDataPort` (`ProductStockMovementReportDataAdapter`), `StockMovementReportDataProvider` |
| **Receipts & Payments** | `RpTransactionRepository` | `RpReportDataPort` (`RpReportDataAdapter`) |
| **Cash Registers** | `CashRegisterRepository` | Cash Register Operational Reports |

---

## 2. Canonical Filter Model (`ReportQueryFilter`)

All reporting data ports and queries now consume `ReportQueryFilter`, located at:
`lib/core/report_engine/domain/models/report_query_filter.dart`

### Key Fields & Rules:
1. **Multi-Company Scoping (`companyId`)**:
   Every report query requires a non-null `companyId` for tenant isolation.
2. **Posting Scope (`postingScope`)**:
   Financial reports default to `PostingScope.postedOnly`. Draft or unposted entries are filtered out unless explicitly requested (`PostingScope.all` or `PostingScope.unpostedOnly`).
3. **Date Filters (`fromDate`, `toDate`, `asOfDate`)**:
   Standardized UTC/date boundaries for period-based and snapshot reports.
4. **Entity Filters (`accountUuid`, `customerUuid`, `warehouseUuid`, `productUuid`, `currencyCode`)**:
   Optional entity scoping parameters.

---

## 3. Financial Correctness Gating

- **Default Scope**: Financial reports (Journal Book, Trial Balance, Account Statement, Balance Sheet, Profit & Loss) set `postingScope = PostingScope.postedOnly` by default.
- **Verification**: Programmatically verified via `test/reports_financial_posting_scope_test.dart` and `test/reports_multi_company_isolation_test.dart`.

---

## 4. Report Engine Exports
`lib/core/report_engine/report_engine.dart` exports all core report engine models, execution contexts, providers, and filter specifications for clean modular imports across the application.
