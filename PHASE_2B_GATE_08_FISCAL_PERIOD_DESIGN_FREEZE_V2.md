# NEXABIZ ERP — GATE-08 V2
# FISCAL PERIOD + FX REVALUATION + FISCAL YEAR CLOSING ARCHITECTURE SPECIFICATION & DESIGN FREEZE

> **DOCUMENT STATUS: DESIGN FROZEN V2**  
> **IMPLEMENTATION STATUS: NOT STARTED (STRICTLY PROHIBITED IN GATE-08 V2 REVISION PHASE)**  
> **DATABASE MIGRATIONS: NOT STARTED**  
> **GATE-01..07 STATUS: CLOSED AND LOCKED (FROZEN CONTRACTS)**

---

## A. REVISION EXECUTIVE SUMMARY

### Forensic Context & Audit Summary
Initial GATE-08 drafts contained several critical architectural contradictions, floating-point type leakage, ambiguous period boundary semantics, and security vulnerabilities around authorization capabilities.

This revision performs a rigorous forensic cleanup and freezes the canonical GATE-08 V2 specification:

1. **Floating-Point Storage Elimination**: Fixed `exchange_rate REAL` in database schema. GATE-01 strictly prohibits `REAL`/`FLOAT`/`DOUBLE`. All exchange rates are now persisted as `exchange_rate_scaled INTEGER NOT NULL` with $10^8$ scaling factor.
2. **Financial Document Temporal Coupling**: Business Master Data (Customers, Accounts, Products) does not require a Fiscal Period. Financial Documents (Invoices, Receipts, Journals, Adjustments) MUST be assigned a `postingDate` upon creation and resolve to a valid, operational Fiscal Period (`PERIOD_NOT_FOUND` if missing). Draft documents cannot bypass period existence. Model B (Posting Date Model) is selected.
3. **Internal Authorization Capabilities**: `AuthorizationContext` is no longer a raw caller-supplied enum. It is a **Controlled Domain Capability Object** (`NormalPostingCapability`, `PeriodCloseFxCapability`, `YearEndCloseCapability`, `OpeningBalanceCapability`) issued exclusively by domain services inside atomic DB transactions.
4. **Period Overlap & Resolution**: Identity uniqueness `(company_id, fiscal_year_id, period_number)` is distinguished from Temporal Non-Overlap ($\neg \exists P : P.\text{startDate} \le \text{newEndDate} \land P.\text{endDate} \ge \text{newStartDate}$). Overlap is enforced domain-transactionally. Ambiguous resolution throws `PERIOD_AMBIGUOUS`.
5. **Separation of Completed Facts vs Failed Attempts**: Immutable `financial_period_closing_records` (Completed Fact) is separated from `financial_period_closing_attempts` (Failed Attempt Log). Failed attempts do not block subsequent retries.
6. **Deterministic 20-Step Year-End Sequence & Model A Next FY Generation**: Year-End Close executes a single 20-step atomic workflow that closes P&L, carries forward Balance Sheet accounts, automatically creates Next FY, Period 1, Opening Balance Journal, builds Opening Boundary projection, reconciles balances, and locks the fiscal year.
7. **Opening Boundary Double-Counting Prevention**: Source of truth remains `JournalEntries` + `JournalLines`. `FiscalYearOpeningBoundary` is a derived projection only. Query Model A is selected ($\text{OpeningBoundary} + \text{Current Year JournalLines EXCLUDING Opening Journal}$ where `voucherType = 'opening_balance'`).
8. **Reporting Query Boundary**: Current-year reporting is strictly bounded by `postingDate >= FY.startDate AND postingDate <= FY.endDate`. Historical closed-year `JournalLines` are never scanned for current-year reports.

---

## B. BLOCKER MATRIX

| ID | Finding | Severity | Resolution | Evidence |
| :--- | :--- | :--- | :--- | :--- |
| **BLK-01** | `exchange_rate REAL` column in `financial_period_closing_rates` violated GATE-01 Int64 scaled integer constraint. | **BLOCKER** | Corrected schema to `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale). | **PROVEN**: Schema Section G. |
| **BLK-02** | Draft financial documents lacked mandatory temporal coupling to Fiscal Period. | **BLOCKER** | Enforced Model B: Every financial document requires `postingDate` resolving to an operational period upon creation. | **PROVEN**: Section C Target 01 & 02. |
| **BLK-03** | `AuthorizationContext` was a raw caller-controlled enum allowing posting gate bypass. | **BLOCKER** | Replaced with internal Domain Capability Objects issued exclusively inside atomic DB transactions. | **PROVEN**: Section C Target 05. |
| **BLK-04** | Failed period close record blocked subsequent retry due to DB `UNIQUE(company_id, period_id)` index. | **BLOCKER** | Separated `financial_period_closing_records` (Completed Fact) from `financial_period_closing_attempts` (Audit Log). | **PROVEN**: Section C Target 14 & Schema Section G. |
| **BLK-05** | Double-counting risk between Opening Balance Journal and `FiscalYearOpeningBoundary`. | **BLOCKER** | Selected Query Model A excluding `voucherType = 'opening_balance'` from current-year movement sum. | **PROVEN**: Section C Target 18. |
| **BLK-06** | Unique index on period number was falsely claimed to prevent date range overlap. | **BLOCKER** | Defined date range overlap as a domain-transactional invariant ($\neg \exists P : P.\text{startDate} \le \text{newEndDate} \land P.\text{endDate} \ge \text{newStartDate}$). | **PROVEN**: Section C Target 07. |

---

## C. REVISED GATE-08 V2 SPECIFICATION

### Target 01: Financial Document Creation / Draft Period Rule
- Business Master Data (Customer, Supplier, Product, Warehouse, Cash Box, Account, Subject, Currency, Exchange Rate Master) DOES NOT require a Fiscal Period.
- Financial Documents (Sales Invoice, Purchase Invoice, Receipt, Payment, Expense, Journal Voucher, Financial Stock Movement, Credit Note, Debit Note, Adjustment, Transfer) MUST be assigned a valid `postingDate` upon creation (defaulting to current date), which MUST resolve to an operational Fiscal Period (`OPEN` or `REOPENED`).
- If no period exists for `postingDate`, document creation fails (`PERIOD_NOT_FOUND`).
- If period is `DRAFT`, `CLOSING`, `CLOSED`, or `LOCKED`, document creation fails (`PERIOD_NOT_OPERATIONAL` / `PERIOD_CLOSED`).
- Editing a draft document revalidates the period if `postingDate` changes.

### Target 02: Document Date vs Posting Date (Model B Selection)
- **`documentDate`**: Commercial/business date (vendor invoice date, receipt date). Mutable in Draft state. Does NOT determine Fiscal Period once `postingDate` is set.
- **`postingDate`**: Accounting-effective calendar date (`YYYY-MM-DD`). Determines Fiscal Period, posting authorization, ledger placement, and FX snapshot scope.
- `postingDate` becomes **100% IMMUTABLE** after posting.

### Target 03: Period State Semantics
- **`DRAFT`**: Structurally created but non-operational. Financial document creation/editing/posting is BLOCKED (`PERIOD_NOT_OPERATIONAL`).
- **`OPEN`**: Operational. Normal financial operations allowed.
- **`REOPENED`**: Operational. Normal financial operations allowed under permission `accounting.periods.reopen` + mandatory audit reason.
- **`CLOSING`**: Controlled close in progress. Normal user posting BLOCKED (`PERIOD_CLOSING`). Only internal `PeriodCloseFxCapability` allowed.
- **`CLOSED`**: Operational posting BLOCKED (`PERIOD_CLOSED`). Reversal into closed period is forbidden.
- **`LOCKED`**: Permanent financial freeze achieved after Year-End Close. Reopen is FORBIDDEN (`PERIOD_LOCKED`).

### Target 04: Posting Authorization Transaction Boundary (`FP-INV-07`)
> **Posting authorization has no validity outside the transaction that commits the corresponding JournalEntry.**

```text
BEGIN ATOMIC DB TRANSACTION
    ├── Resolve Period: resolvePeriod(companyId, postingDate)
    ├── Validate Period State & Obtain Domain Capability Object
    ├── Validate Financial Invariants & Scaled Int64 Balances
    ├── Persist Journal & JournalLines via PostingEngine
COMMIT ATOMIC DB TRANSACTION
```

### Target 05: Authorization Capability Security
`AuthorizationContext` is an internal domain capability object issued exclusively by financial domain services inside atomic DB transactions:
- `NormalPostingCapability`: Issued for standard business transactions when period is `OPEN` or `REOPENED`.
- `PeriodCloseFxCapability`: Issued exclusively by `PeriodClosingService` during atomic close in `CLOSING` state.
- `YearEndCloseCapability`: Issued exclusively by `YearEndClosingService`.
- `OpeningBalanceCapability`: Issued exclusively during Fiscal Year initialization.

`PostingEngine` rejects any journal submission lacking a valid domain capability object.

### Target 06: Period Resolution (`resolvePeriod`)
- Input: `companyId` (mandatory), `postingDate` (mandatory calendar date `YYYY-MM-DD`).
- Caller-supplied `periodId` injection attempts are **STRICTLY IGNORED**.
- Resolution rules:
  - 0 matching rows $\implies$ `PERIOD_NOT_FOUND`.
  - 1 matching row $\implies$ Success (`FinancialFiscalPeriod`).
  - $>1$ matching rows $\implies$ `PERIOD_AMBIGUOUS` (Domain configuration error).

### Target 07: Period Overlap Domain Invariant
`UNIQUE(company_id, fiscal_year_id, period_number)` enforces identity uniqueness, NOT temporal non-overlap.
Temporal non-overlap is enforced at domain creation/update time and transactionally:

$$\neg \exists P : (P.\text{startDate} \le \text{newEndDate}) \land (P.\text{endDate} \ge \text{newStartDate})$$

### Target 08: Fiscal Year / Period State Machine Consistency
- **`FY.OPEN`**: Child periods may be in `DRAFT`, `OPEN`, `CLOSING`, `CLOSED`, or `REOPENED`.
- **`FY.CLOSED`**: No child period may remain in `OPEN`, `REOPENED`, or `CLOSING` state. All child periods MUST be `CLOSED`.
- **`FY.LOCKED`**: All child periods MUST be `LOCKED`. Reopening a period in a `LOCKED` FY is strictly FORBIDDEN.
- Fiscal Year transition `CLOSED` $\rightarrow$ `LOCKED` occurs exclusively upon completion of 20-step Year-End Close. Fiscal Year reopening is FORBIDDEN.

### Target 09: Period Close User Decision
When closing a period, the UI/API MUST explicitly prompt:
$$\text{Close this period with FX revaluation? } [\text{YES}] \quad [\text{NO}]$$
Inferring the answer silently from company settings is FORBIDDEN.
- If **NO**: System closes period without FX revaluation.
- If **YES**: System collects and validates required exchange rates.

### Target 10: FX Eligibility Contract
Eligibility derives strictly from GATE-01 Account Currency Policy:
- **Eligible**: Foreign-currency monetary accounts (Customer/Supplier foreign balances, Foreign Cash/Bank accounts).
- **Ineligible**: Functional-only accounts, revenue, expense, COGS, and non-monetary balance sheet items.

### Target 11: FX Rate Storage — Scaled Integer Mandate ($10^8$)
`REAL`, `FLOAT`, or `DOUBLE` in database schema or in-memory rate calculations are **STRICTLY FORBIDDEN**.
Exchange rates are stored as scaled integers ($10^8$ scale):
`exchange_rate_scaled INTEGER NOT NULL` (e.g. $1\text{ USD} = 530.00000000\text{ YER} \implies 53000000000$).

### Target 12: FX Snapshot Immutability
User-confirmed rates are persisted in `financial_period_closing_rates`. Modifying `FinancialExchangeRates` master data after close NEVER alters historical snapshots or FX revaluation entries.

### Target 13: Period Close Atomicity
Period close executes inside a single atomic DB transaction:
`Preflight` $\rightarrow$ `CLOSING` status $\rightarrow$ `FX Snapshot` $\rightarrow$ `Post FX Journal` $\rightarrow$ `Persist Completed Fact` $\rightarrow$ `CLOSED` status $\rightarrow$ `COMMIT`.
Any failure triggers `ROLLBACK`, leaving no permanent `CLOSING` state.

### Target 14: Close Retry / Idempotency
- **`financial_period_closing_records`**: Immutable record of a completed close (Unique per `company_id, period_id`).
- **`financial_period_closing_attempts`**: Audit log of failed attempts. Failed attempts do NOT block subsequent retries.
- Re-executing close on an already `CLOSED` period returns the existing completed record (Idempotent Success).

### Target 15: Deterministic 20-Step Year-End Closing Sequence
1. Verify Fiscal Year exists and `companyId` context matches.
2. Verify all expected fiscal periods exist.
3. Identify final period of the fiscal year.
4. If final period is `OPEN` or `REOPENED`, execute final Period Close workflow.
5. Verify ALL child periods are now in `CLOSED` state.
6. Perform Year-End preflight check (no unposted drafts).
7. Calculate final year-end P&L account balances.
8. Resolve `Retained Earnings` account via Account Resolution (GATE-05/06).
9. Post Year-End P&L Closing Journal Entry (`YEAR_END_CLOSE`), zeroing P&L balances.
10. Calculate permanent account (Balance Sheet) carry-forward balances.
11. Create Next Fiscal Year (Model A Selection).
12. Create Next Fiscal Year Period 1.
13. Generate Opening Balance Journal Entry (`OPENING_BALANCE`) in Period 1 of Next FY via `PostingEngine`.
14. Build Next Fiscal Year Opening Boundary Projection (`financial_fiscal_year_opening_boundaries`).
15. Reconcile previous year closing balances vs next year opening boundary (`FISCAL_YEAR_OPENING_BALANCE_MISMATCH`).
16. Persist immutable `financial_fiscal_year_closing_records` row.
17. Lock current Fiscal Year (`FiscalYear.status = LOCKED`).
18. Set all child periods of current FY to `LOCKED`.
19. Verify resulting child-period and Fiscal Year state consistency.
20. Commit atomic DB transaction.

### Target 16: Year-End Accounting Semantics
- **Temporary Accounts (P&L)**: Revenue, Expense, COGS ending balances zeroed as of `endDate`. Net result transferred to Retained Earnings. Opening balances for Next FY start from **ZERO**.
- **Permanent Accounts (Balance Sheet)**: Assets, Liabilities, Equity carry forward ending balances into Next FY, preserving `companyId`, `accountId`, `subjectId`, `currencyCode`, and scaled Int64 balance.

### Target 17: Next Fiscal Year Creation (Model A Selection)
Model A selected: Year-End Close automatically creates Next Fiscal Year, Period 1, Opening Balance Journal, and builds Opening Boundary snapshot within the single atomic Year-End workflow.

### Target 18: Opening Journal vs Opening Boundary (Preventing Double Counting)
- Source of truth: `JournalEntries` + `JournalLines`.
- `FiscalYearOpeningBoundary`: Derived performance projection ONLY.
- Query Model A Selection:
  $$\text{Current Year Balance} = \text{OpeningBoundary}(\text{CurrentYear}) + \sum \text{JournalLines}(\text{CurrentYear EXCLUDING } \text{voucherType} = \text{'opening\_balance'})$$

### Target 19: Opening Boundary Rebuildability
If `financial_fiscal_year_opening_boundaries` projection is corrupt or missing, it can be 100% rebuilt from authoritative historical `JournalLines`.

### Target 20: Current-Year Reporting Query Boundary
Current-year reports query:
$$\text{postingDate} \ge \text{fiscalYear.startDate} \quad \land \quad \text{postingDate} \le \text{fiscalYear.endDate}$$
Historical closed-year `JournalLines` are NOT scanned for current-year reports. Historical reports explicitly target the requested historical Fiscal Year.

### Target 21: Period Reopen Semantics
- Reopening transits `CLOSED` $\rightarrow$ `REOPENED`. Requires permission `accounting.periods.reopen` + non-empty reason + audit event.
- Reopening a period in a `LOCKED` Fiscal Year is FORBIDDEN (`FISCAL_YEAR_LOCKED`).
- Reopening NEVER mutates or deletes historical journals.

### Target 22: Closed Period Reversal
Reversing a journal originally posted in a `CLOSED` period does NOT reopen the period. The reversal journal is posted into an active `OPEN` or `REOPENED` period with a new `postingDate` and references `reversalOfJournalId`.

### Target 23: Tenancy Contract
All entities are `company_id` scoped (`CHECK(length(company_id) = 36)`). Foreign keys enforce composite tenant matching. Cross-company access attempts raise `CROSS_TENANT_PERIOD`.

---

## D. AUTHORITY MAP

| Component / Concept | Authoritative Authority | Responsibility |
| :--- | :--- | :--- |
| **Business Master Data** | Master Data Repositories | Maintain customer, product, account identities (NO period required). |
| **Financial Documents** | Commercial / Finance Modules | Create business documents with mandatory `postingDate` resolved to Fiscal Period. |
| **Fiscal Period** | `FinancialPeriodResolver` / Gate | Authoritative temporal existence and authorization boundary. |
| **Fiscal Year** | Fiscal Year Domain Service | FY lifecycle, state machine, and Year-End Close coordination. |
| **PostingEngine** | `PostingEngine` (GATE-04) | Sole canonical ledger writer and financial balance mutation authority. |
| **JournalEntries / Lines** | Core Financial Ledger | Single financial source of truth for balances and auditability. |
| **FX Snapshot** | `financial_period_closing_rates` | Immutable historical evidence of exchange rates used for period revaluation. |
| **Opening Balance Journal** | `PostingEngine` (`OPENING_BALANCE`) | Authoritative ledger entry for permanent account carry-forward. |
| **Opening Boundary** | `financial_fiscal_year_opening_boundaries`| Derived performance projection snapshot for fast current-year queries. |
| **Financial Reports** | Financial Reporting Engine | Bounded queries relying on Opening Boundary + current-year movements. |

---

## E. STATE MACHINES

### 1. Fiscal Period State Machine

| From State | To State | Trigger / Condition | Authority / Permission |
| :--- | :--- | :--- | :--- |
| **Initial** | `DRAFT` | Period structure creation | System / FY Creation |
| `DRAFT` | `OPEN` | Operational activation | `accounting.periods.manage` |
| `OPEN` | `CLOSING` | Close workflow initiated | `PeriodClosingService` (Internal) |
| `CLOSING` | `CLOSED` | Atomic close success | `PeriodClosingService` (Atomic DB Commit) |
| `CLOSING` | `OPEN` / `REOPENED`| Atomic close failure/rollback | Atomic Transaction Rollback |
| `CLOSED` | `REOPENED` | Reopen period request | `accounting.periods.reopen` + Reason + Audit |
| `REOPENED` | `CLOSING` | Re-close workflow initiated | `PeriodClosingService` (Internal) |
| `CLOSED` | `LOCKED` | Year-End Close completed | `YearEndClosingService` (Atomic DB Commit) |
| `LOCKED` | *Any* | **FORBIDDEN** | **NONE (Irreversible)** |

### 2. Fiscal Year State Machine

| From State | To State | Trigger / Condition | Authority / Permission |
| :--- | :--- | :--- | :--- |
| **Initial** | `DRAFT` | Fiscal Year structure creation | System / Admin |
| `DRAFT` | `OPEN` | Fiscal Year activation | `accounting.fiscal_years.manage` |
| `OPEN` | `CLOSED` | All child periods closed | FY Closing Preflight |
| `CLOSED` | `LOCKED` | 20-step Year-End Close complete | `YearEndClosingService` (Atomic DB Commit) |
| `LOCKED` | *Any* | **FORBIDDEN** | **NONE (Irreversible)** |

---

## F. TRANSACTION BOUNDARIES

```text
1. NORMAL POSTING TRANSACTION BOUNDARY:
BEGIN ATOMIC DB TRANSACTION
    ├── resolvePeriod(companyId, postingDate)
    ├── Assert period.status IN ('OPEN', 'REOPENED')
    ├── Obtain NormalPostingCapability
    ├── Execute Business Logic & Validate Int64 Balances
    ├── PostingEngine.post(journal, capability)
COMMIT ATOMIC DB TRANSACTION

2. PERIOD CLOSE TRANSACTION BOUNDARY:
BEGIN ATOMIC DB TRANSACTION
    ├── Assert period.status IN ('OPEN', 'REOPENED') & no unposted drafts
    ├── UPDATE financial_fiscal_periods SET status = 'closing'
    ├── IF closeWithFxRevaluation = true:
    │     ├── Validate all required closing rates exist
    │     ├── Persist scaled rates into financial_period_closing_rates
    │     ├── Obtain PeriodCloseFxCapability
    │     └── PostingEngine.post(fxJournal, capability)
    ├── Persist completed fact into financial_period_closing_records
    ├── UPDATE financial_fiscal_periods SET status = 'closed'
COMMIT ATOMIC DB TRANSACTION

3. YEAR-END CLOSE TRANSACTION BOUNDARY (MODEL A):
BEGIN ATOMIC DB TRANSACTION
    ├── Verify all periods of current FY are in 'closed' state
    ├── Post P&L Closing Journal (YEAR_END_CLOSE capability) -> zero P&L
    ├── Calculate permanent account carry-forward balances
    ├── Create Next Fiscal Year & Period 1
    ├── Post Opening Balance Journal (OPENING_BALANCE capability) into Period 1
    ├── Build financial_fiscal_year_opening_boundaries projection snapshot
    ├── Reconcile closing vs opening balances
    ├── Persist financial_fiscal_year_closing_records
    ├── UPDATE financial_fiscal_years SET status = 'locked'
    ├── UPDATE financial_fiscal_periods SET status = 'locked' WHERE fiscal_year_id = currentFY
COMMIT ATOMIC DB TRANSACTION
```

---

## G. DATABASE CONTRACT (`packages/financial`)

```sql
-- 1. Fiscal Years Table
CREATE TABLE IF NOT EXISTS financial_fiscal_years (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    code TEXT NOT NULL CHECK(length(code) >= 1 AND length(code) <= 32),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 128),
    start_date INTEGER NOT NULL, -- UTC day epoch ms
    end_date INTEGER NOT NULL,   -- UTC day epoch ms
    status TEXT NOT NULL CHECK(status IN ('draft', 'open', 'closed', 'locked')),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    closed_at INTEGER,
    created_by TEXT,
    closed_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fy_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT chk_fy_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_fy_comp_id ON financial_fiscal_years(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_fy_comp_code ON financial_fiscal_years(company_id, code);

-- 2. Fiscal Periods Table
CREATE TABLE IF NOT EXISTS financial_fiscal_periods (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    period_number INTEGER NOT NULL CHECK(period_number > 0),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 64),
    start_date INTEGER NOT NULL, -- UTC day epoch ms
    end_date INTEGER NOT NULL,   -- UTC day epoch ms
    status TEXT NOT NULL CHECK(status IN ('draft', 'open', 'closing', 'closed', 'reopened', 'locked')),
    opened_at INTEGER,
    closed_at INTEGER,
    reopened_at INTEGER,
    reopen_reason TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fp_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_fp_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE CASCADE,
    CONSTRAINT chk_fp_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_fp_comp_id ON financial_fiscal_periods(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_fp_comp_fy_num ON financial_fiscal_periods(company_id, fiscal_year_id, period_number);
CREATE INDEX IF NOT EXISTS idx_fp_comp_dates ON financial_fiscal_periods(company_id, start_date, end_date);

-- 3. Period Closing Records Table (Completed Fact)
CREATE TABLE IF NOT EXISTS financial_period_closing_records (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    closing_date INTEGER NOT NULL,
    fx_revaluation_executed INTEGER NOT NULL DEFAULT 0,
    journal_entry_id TEXT CHECK(journal_entry_id IS NULL OR length(journal_entry_id) = 36),
    created_by TEXT,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pcr_comp_period ON financial_period_closing_records(company_id, period_id);

-- 4. Period Closing Attempts Table (Audit Log of Failures)
CREATE TABLE IF NOT EXISTS financial_period_closing_attempts (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    attempted_at INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('failed', 'aborted')),
    failure_reason TEXT NOT NULL,
    attempted_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_pca_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pca_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE CASCADE
);

-- 5. Period Closing Rates Snapshot Table (Scaled Integer Rates 10^8)
CREATE TABLE IF NOT EXISTS financial_period_closing_rates (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    period_closing_record_id TEXT NOT NULL CHECK(length(period_closing_record_id) = 36),
    from_currency_code TEXT NOT NULL,
    to_currency_code TEXT NOT NULL,
    exchange_rate_scaled INTEGER NOT NULL, -- Scaled 10^8
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_rate_record FOREIGN KEY (company_id, period_closing_record_id) REFERENCES financial_period_closing_records(company_id, id) ON DELETE CASCADE
);

-- 6. Fiscal Year Opening Boundaries Table (Derived Projection)
CREATE TABLE IF NOT EXISTS financial_fiscal_year_opening_boundaries (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    account_id TEXT NOT NULL CHECK(length(account_id) = 36),
    subject_id TEXT CHECK(subject_id IS NULL OR length(subject_id) = 36),
    currency_code TEXT NOT NULL,
    opening_balance_scaled INTEGER NOT NULL, -- Scaled 10^8
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_ob_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_ob_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE CASCADE,
    CONSTRAINT fk_ob_account FOREIGN KEY (company_id, account_id) REFERENCES financial_accounts(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ob_comp_fy_acc_subj ON financial_fiscal_year_opening_boundaries(company_id, fiscal_year_id, account_id, IFNULL(subject_id, ''), currency_code);
```

---

## H. INVARIANT MATRIX (`FP-INV-01..38`)

| ID | Invariant Statement | Enforcement Layer | Test Strategy |
| :--- | :--- | :--- | :--- |
| **FP-INV-01** | Every financial operation resolves to an authoritative `company_id`. | Database FK + Domain | Cross-tenant isolation unit tests |
| **FP-INV-02** | Period date range is valid (`start_date <= end_date`). | DB Check Constraint | Range validation unit tests |
| **FP-INV-03** | Zero overlapping periods permitted within same company. | Domain + Transaction | Overlap creation test |
| **FP-INV-04** | Exactly one period resolves for a valid accounting `postingDate`. | `FinancialPeriodResolver` | Date resolution unit tests |
| **FP-INV-05** | `DRAFT` period is non-operational (`PERIOD_NOT_OPERATIONAL`). | Posting Gate | Attempt post in draft period |
| **FP-INV-06** | `CLOSED`/`LOCKED` periods reject normal financial operations. | Posting Gate | Attempt post in closed period |
| **FP-INV-07** | Posting authorization validated inside transaction committing journal. | Transaction Boundary | Concurrency isolation test |
| **FP-INV-08** | Caller-supplied `periodId` cannot override date-based period resolution. | Domain Resolver | Pass arbitrary `periodId` |
| **FP-INV-09** | FX closing rates stored strictly as scaled integers ($10^8$). | DB Schema (`INTEGER`) | Schema inspection test |
| **FP-INV-10** | FX closing rate snapshots are 100% immutable. | Snapshot Table | Mutate rate master & verify snapshot |
| **FP-INV-11** | Only eligible foreign-currency balances revalued (per GATE-01). | Eligibility Filter | Attempt revaluation on P&L |
| **FP-INV-12** | FX revaluation generated only once per period close operation. | Idempotency Check | Duplicate close request |
| **FP-INV-13** | Failed period close attempts do not block subsequent retry. | Separate Attempt Table | Retry after failed close |
| **FP-INV-14** | Completed close fact is idempotent. | Close Service | Re-execute completed close |
| **FP-INV-15** | Fiscal Year and Period states are strictly consistent. | FY State Machine | Assert FY/Period state rules |
| **FP-INV-16** | Temporary (P&L) accounts close to zero at year-end. | Year-End Journal | Assert P&L balances reset to 0 |
| **FP-INV-17** | Permanent (Balance Sheet) balances carry forward to next year. | Carry-Forward Engine | Assert Asset/Liability balance |
| **FP-INV-18** | Opening balance preserves account/subject/currency identity. | Carry-Forward Engine | Assert opening entry structure |
| **FP-INV-19** | Opening boundary is derived performance projection. | Projection Engine | Rebuild boundary from journals |
| **FP-INV-20** | Opening boundary query model excludes double-counting opening journal. | Query Engine (Model A) | Test current year balance query |
| **FP-INV-21** | Current-year queries do not scan historical closed-year `JournalLines`. | Query Boundary | Assert SQL date filters |
| **FP-INV-22** | Cross-company tenant isolation strictly maintained. | Security Guards | Adversarial tenant attack |
| **FP-INV-23** | Year-End Close operation is atomic. | Transaction Boundary | Rollback on error test |
| **FP-INV-24** | Year-End Close operation is idempotent. | Year-End Service | Re-run Year-End Close |
| **FP-INV-25** | `LOCKED` Fiscal Year cannot be reopened via period reopen. | State Machine | Reopen period in locked FY |
| **FP-INV-26** | All ledger mutations execute through canonical `PostingEngine`. | Posting Engine | Search for direct DB inserts |
| **FP-INV-27** | Financial Documents require `postingDate` upon creation. | Document Service | Create document without date |
| **FP-INV-28** | `postingDate` becomes 100% immutable upon posting. | Document Service | Edit date after posting |
| **FP-INV-29** | `documentDate` change does not alter accounting period. | Document Service | Change documentDate in draft |
| **FP-INV-30** | `AuthorizationContext` capabilities cannot be forged externally. | Domain Capability | Inject fake enum capability |
| **FP-INV-31** | Period Close FX choice requires explicit user prompt. | Close Service | Close without FX prompt |
| **FP-INV-32** | Missing required closing exchange rate aborts period close. | Preflight Check | Omit required rate |
| **FP-INV-33** | Model A Year-End Close creates Next FY, Period 1, & Opening Journal. | Year-End Service | Verify Next FY structure |
| **FP-INV-34** | Opening Balance Journal requires existing valid Next Period 1. | Year-End Service | Post opening journal without period |
| **FP-INV-35** | Reopening period requires permission, reason, and audit event. | Audit System | Reopen without reason |
| **FP-INV-36** | Closed-period reversal posts into active period with new date. | Reversal Service | Reversal in closed period |
| **FP-INV-37** | Historical closed-year lines isolated from current year queries. | Reporting Engine | Query current year balances |
| **FP-INV-38** | Rebuilding Opening Boundary produces identical balances. | Rebuild Utility | Rebuild boundary from history |

---

## I. ADVERSARIAL TEST MATRIX (`ATTACK-FP-01..38`)

| Attack ID | Scenario Description | Expected Outcome | Canonical Error | Enforcement Layer |
| :--- | :--- | :--- | :--- | :--- |
| **ATTACK-FP-01** | Create Financial Document without valid period for `postingDate`. | REJECT | `PERIOD_NOT_FOUND` | Document Service / Gate |
| **ATTACK-FP-02** | Create Financial Document inside `DRAFT` period. | REJECT | `PERIOD_NOT_OPERATIONAL` | Posting Gate |
| **ATTACK-FP-03** | Edit Financial Document inside `CLOSED` period. | REJECT | `PERIOD_CLOSED` | Posting Gate |
| **ATTACK-FP-04** | Post journal with caller-supplied fake `periodId`. | Parameter IGNORED | `PERIOD_NOT_FOUND` | `FinancialPeriodResolver` |
| **ATTACK-FP-05** | `postingDate` resolves to two overlapping periods. | REJECT | `PERIOD_AMBIGUOUS` | `FinancialPeriodResolver` |
| **ATTACK-FP-06** | Company A attempts to post using Company B period. | REJECT | `CROSS_TENANT_PERIOD` | DB FK + Posting Gate |
| **ATTACK-FP-07** | Attempt to persist exchange rate as `REAL`/`FLOAT`. | REJECT | DB Schema Violation | DB Column Constraint |
| **ATTACK-FP-08** | Close with FX selected but one rate missing. | ABORT close | `FX_REVALUATION_RATE_MISSING`| Preflight Check |
| **ATTACK-FP-09** | Attempt FX revaluation on non-eligible functional account. | REJECT | `FX_REVALUATION_NOT_ALLOWED` | Eligibility Filter |
| **ATTACK-FP-10** | Duplicate FX revaluation submission. | Idempotent replay | Success (Cached Fact) | Close Service |
| **ATTACK-FP-11** | Retry period close after previous failed attempt. | ALLOWED | Success (Completed Fact) | Close Service |
| **ATTACK-FP-12** | Crash occurs mid-way through period close in `CLOSING`. | Rollback | Transaction Rollback | Atomic DB Transaction |
| **ATTACK-FP-13** | Year-End Close attempted while final period is `OPEN`. | Auto-close / REJECT | `YEAR_END_NOT_READY` | Year-End Service |
| **ATTACK-FP-14** | Year-End Close attempted with missing period in year. | REJECT | `YEAR_END_NOT_READY` | Year-End Service |
| **ATTACK-FP-15** | Year-End Close attempted while FY is already `LOCKED`. | REJECT | `FISCAL_YEAR_LOCKED` | Year-End Service |
| **ATTACK-FP-16** | Duplicate Opening Balance Journal generation attempt. | Idempotent replay | Success (Cached Entry) | Year-End Service |
| **ATTACK-FP-17** | Opening Boundary double counting Opening Balance Journal. | PREVENTED | Query Model A Exclusion | Query Engine |
| **ATTACK-FP-18** | Current-year report scanning previous years' `JournalLines`. | PREVENTED | Query Date Range Filter | Reporting Engine |
| **ATTACK-FP-19** | Attempt to reopen period inside `LOCKED` Fiscal Year. | REJECT | `FISCAL_YEAR_LOCKED` | State Machine |
| **ATTACK-FP-20** | Cross-company `OpeningBoundary` access attempt. | REJECT | `CROSS_TENANT_PERIOD` | DB FK + Security Guard |
| **ATTACK-FP-21** | Forged raw `AuthorizationContext` enum passed by module. | REJECT | `CAPABILITY_INVALID` | `PostingEngine` |
| **ATTACK-FP-22** | Posting journal outside atomic DB transaction. | REJECT | `TRANSACTION_REQUIRED` | `PostingEngine` |
| **ATTACK-FP-23** | Changing `postingDate` after document posting. | REJECT | `DOCUMENT_POSTED_IMMUTABLE` | Document Repository |
| **ATTACK-FP-24** | Attempt to create period overlapping existing date range. | REJECT | `PERIOD_OVERLAP` | Period Service / DB |
| **ATTACK-FP-25** | Attempt to modify snapshotted FX rate after close. | REJECT | `SNAPSHOT_IMMUTABLE` | Snapshot Table / DB |
| **ATTACK-FP-26** | Attempt to close FY without Retained Earnings resolution. | REJECT | `ACCOUNT_RESOLUTION_FAILED` | Account Resolver |
| **ATTACK-FP-27** | Reopen period without non-empty audit reason. | REJECT | `REASON_REQUIRED` | Period Service |
| **ATTACK-FP-28** | Reversal of closed-period journal using original date. | REJECT | `PERIOD_CLOSED` | Reversal Service |
| **ATTACK-FP-29** | Direct SQL insertion into `JournalLines` bypassing Engine. | PREVENTED | DB Triggers / Service Layer | Security Architecture |
| **ATTACK-FP-30** | Attempt to delete a `LOCKED` Fiscal Year or Period. | REJECT | `ENTITY_LOCKED` | DB FK Restrict |
| **ATTACK-FP-31** | Attempt FX revaluation on Revenue/Expense account. | REJECT | `FX_REVALUATION_NOT_ALLOWED` | Eligibility Filter |
| **ATTACK-FP-32** | Year-End Close reconciliation failure between closing & opening. | ABORT Year-End | `FISCAL_YEAR_OPENING_BALANCE_MISMATCH` | Reconciliation Step |
| **ATTACK-FP-33** | Reopen `LOCKED` Fiscal Year directly. | REJECT | `FISCAL_YEAR_LOCKED` | State Machine |
| **ATTACK-FP-34** | Post opening balance journal in an `OPEN` active period. | REJECT | `CAPABILITY_INVALID` | `PostingEngine` |
| **ATTACK-FP-35** | Query historical year report using current year boundary. | REJECT | `HISTORICAL_QUERY_INVALID` | Reporting Engine |
| **ATTACK-FP-36** | Attempt period close with zero periods defined in FY. | REJECT | `FISCAL_YEAR_EMPTY` | Preflight Check |
| **ATTACK-FP-37** | Modifying exchange rate master data after FX snapshot creation. | Historical Immutable | Historical Entry Unchanged | Snapshot Table |
| **ATTACK-FP-38** | Attempt to reuse `PeriodCloseFxCapability` outside close transaction.| REJECT | `CAPABILITY_EXPIRED` | Domain Capability |

---

## J. LEGACY REPLACEMENT MATRIX

| Current Legacy Mechanism | Replacement Architecture | Implementation-Phase Removal Requirement |
| :--- | :--- | :--- |
| `accounting_fiscal_closed_through` setting | Explicit company-scoped `financial_fiscal_periods` table. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove setting lookup). |
| Tenantless `findPeriodContaining` | `FinancialPeriodResolver.resolve(companyId, postingDate)`. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove tenantless method). |
| In-memory `FiscalPeriodPolicy` | Domain `FinancialPeriodGate` executing inside DB transaction. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove in-memory policy). |
| Inline module date checks in Sales/Purchases | Standardized call to canonical Posting Gate. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove inline checks). |
| Null-company `AccountingPeriodsCompanion` | Mandatory `company_id TEXT NOT NULL` schema contract. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove null-company support). |
| Floating-point exchange rates in DB | `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale). | **REQUIRED FOR IMPLEMENTATION PHASE** (Migrate schema column). |

---

## K. FINAL GATE VERDICT

```text
GATE-08 V2 — DESIGN FROZEN

Implementation Status: NOT STARTED
Database Changes: NOT STARTED
Migration: NOT STARTED
Tests Implementation: NOT STARTED

AUTHORITY: READY FOR IMPLEMENTATION PHASE
```
