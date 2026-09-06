# RE-10 — SECURITY / PERMISSIONS / MULTI-COMPANY

## 1. Role-Based Access Control (RBAC) Enforcement

NexaBiz ERP enforces granular permission checks at both the route navigation layer (`RouteAccessRule`) and the UI provider/view layer (`PermissionService`).

### Registered Report Permission Package (`reportsPermissionPackage`)
- `reports.view`: Legacy/global read access for reporting catalog.
- `reports.sales_period.view` & `reports.sales_period.export`: Operational sales report permissions.
- `reports.account_statement.view` & `reports.account_statement.export`: Account statement permissions.
- `reports.trial_balance.view` & `reports.trial_balance.export`: Trial balance permissions.
- `reports.journal_book.view` & `reports.journal_book.export`: Journal book permissions.
- `reports.general_ledger.view` & `reports.general_ledger.export`: General Ledger permissions.
- `reports.income_statement.view` & `reports.income_statement.export`: Income Statement / P&L permissions.
- `reports.balance_sheet.view` & `reports.balance_sheet.export`: Balance Sheet permissions.
- `reports.receivables_payables.view` & `reports.receivables_payables.export`: Receivables & Payables permissions.
- `reports.cash_flow.view` & `reports.cash_flow.export`: Cash Flow statement permissions.

---

## 2. Multi-Company Tenant Isolation

- **Data Boundary Scoping**: Every report query filter requires a valid `companyId`. Queries in `JournalRepository`, `SalesRepository`, and `AccountRepository` append mandatory `company_id = ?` clauses.
- **Cross-Tenant Access Rejection**: Rejection of cross-company data access is enforced at the repository SQL level. Attempts to pass another company's UUID yield zero rows.
- **Export Isolation**: Export builders (PDF, CSV, Excel) generate files solely from company-scoped datasets.
