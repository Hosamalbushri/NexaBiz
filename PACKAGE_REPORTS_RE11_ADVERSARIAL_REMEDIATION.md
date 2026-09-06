# RE-11 — ADVERSARIAL TESTING + REMEDIATION

## 1. Executed Adversarial Test Suite (`test/reports_adversarial_re11_test.dart`)

All 3 adversarial scenario tests were executed and passed:

### Scenario 1: Financial Reconciliation (Sale & Receipts)
- **Inputs**:
  - Sale: 1000 SAR (DR Accounts Receivable 1000, CR Sales Revenue 1000, DR COGS 600, CR Inventory 600)
  - Receipt 1: 400 SAR (DR Cash 400, CR Accounts Receivable 400)
  - Receipt 2: 600 SAR (DR Cash 600, CR Accounts Receivable 600)
- **Report Verification Results**:
  - Sales Revenue = 1000 SAR
  - Total Receipts = 1000 SAR
  - Net Outstanding Balance = 0 SAR
  - Cash Register Inflow = +1000 SAR
  - **Verdict**: PASS

### Scenario 2: Inventory Costing & COGS Reconciliation
- **Inputs**: Costing engine historical cost = 600 SAR for sold item.
- **Report Verification Results**:
  - Income Statement COGS line = 600 SAR
  - Sales Gross Profit = 400 SAR (1000 Revenue - 600 COGS)
  - **Verdict**: PASS

### Scenario 3: Multi-Company Tenant Isolation Remediation
- **Discovery**: During initial test execution, querying with `companyId: 'comp-unauthorized'` against `IncomeStatementReportDataAdapter` returned global data because `JournalRepository.listTrialBalance` interface lacked explicit `companyId` scoping.
- **Remediation Executed**:
  1. Updated `JournalRepository.listTrialBalance` and `listJournalBookLines` interfaces to accept `String? companyId`.
  2. Updated `JournalRepositoryImpl` to enforce `companyId` in SQL queries (`company_id = ?`).
  3. Updated `IncomeStatementReportDataAdapter`, `BalanceSheetReportDataAdapter`, `TrialBalanceReportDataAdapter`, and `GeneralLedgerReportDataAdapter` to pass `filter.companyId` down to database read methods.
- **Rerun Verdict**: PASS (Unauthorized tenant queries yield exactly 0 rows).
