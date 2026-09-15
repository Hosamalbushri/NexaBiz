# NEXABIZ ERP — GATE-08 V3
# FISCAL PERIOD + FX REVALUATION + FISCAL YEAR CLOSING ARCHITECTURE SPECIFICATION & DESIGN FREEZE

> **DOCUMENT STATUS: DESIGN FROZEN V3**  
> **IMPLEMENTATION STATUS: NOT STARTED (STRICTLY PROHIBITED IN GATE-08 V3 REVISION PHASE)**  
> **DATABASE MIGRATIONS: NOT STARTED**  
> **GATE-01..07 STATUS: CLOSED AND LOCKED (FROZEN CONTRACTS)**

---

## 1. REVISION VERDICT

```text
NEXABIZ ERP — GATE-08 V3

DESIGN STATUS: FROZEN

IMPLEMENTATION STATUS: NOT STARTED

DATABASE MIGRATIONS: NOT STARTED

TEST IMPLEMENTATION: NOT STARTED

GATE-01..07: CLOSED / LOCKED / UNCHANGED

AUTHORITY: READY FOR IMPLEMENTATION PHASE
```

---

## 2. FORENSIC FINDINGS

| ID | Finding | Severity | Existing V2 Section | Resolution |
| :--- | :--- | :--- | :--- | :--- |
| **BLK-01** | Post-closing Year-End Journal execution contradicted `CLOSED` status posting prohibition. | **BLOCKER** | Section C Target 15 | **RESOLVED**: Year-End Close is a single atomic workflow; Year-End Journal is posted while final period is in `CLOSING` state via internal `YearEndCloseCapability`. Final period transitions to `CLOSED` upon workflow completion. |
| **BLK-02** | Rate snapshot referenced future `period_closing_record_id` (Completed Fact) before fact creation. | **BLOCKER** | Section C Target 14 & Schema | **RESOLVED**: Introduced explicit `financial_period_closing_operations` (`PeriodClosingOperation`). Rates reference `closing_operation_id`. Completed Fact references `closing_operation_id`. |
| **BLK-03** | Referenced `financial_fiscal_year_closing_records` table lacked physical schema definition. | **BLOCKER** | Section G Schema | **RESOLVED**: Defined full physical schema for `financial_fiscal_year_closing_records` with composite tenant FKs, `UNIQUE(company_id, fiscal_year_id)`, and journal entry references. |
| **BLK-04** | Ambiguity between Opening Balance Journal movements and `FiscalYearOpeningBoundary`. | **BLOCKER** | Section C Target 18 | **RESOLVED**: Defined Query Model A: `CurrentYearBalance(FY) = OpeningBoundary(FY) + CurrentYearMovements(FY EXCLUDING voucherType = 'opening_balance')`. |
| **BLK-05** | Ambiguity in Opening Boundary rebuild derivation from historical journals. | **BLOCKER** | Section C Target 19 | **RESOLVED**: Derivation explicitly defined: `OpeningBoundary(FY N) = Permanent Account Ending Balances of FY N-1` derived deterministically from historical `JournalLines` of prior closed years. |
| **BLK-06** | Ambiguity in Period Close retry vs Completed Fact vs Failed Attempt audit records. | **BLOCKER** | Section C Target 14 | **RESOLVED**: Separated execution identity (`PeriodClosingOperation`), historical completion (`financial_period_closing_records`), and failure audit (`financial_period_closing_attempts`). |
| **HIGH-01** | Missing Fiscal Year temporal non-overlap invariant. | **HIGH** | Section C Target 07 | **RESOLVED**: Added explicit FY non-overlap invariant: $\neg \exists FY : FY.\text{startDate} \le \text{newEndDate} \land FY.\text{endDate} \ge \text{newStartDate}$. |
| **HIGH-02** | Ambiguous "all expected periods" phrase for Year-End Close preflight. | **HIGH** | Section C Target 15 | **RESOLVED**: Enforced contiguous period coverage: `Period N.endDate + 1 day = Period N+1.startDate` spanning `FY.startDate` through `FY.endDate`. |
| **HIGH-03** | Opening Balance Journal posting into `DRAFT` Period 1 violated period operational rules. | **HIGH** | Section C Target 17 | **RESOLVED**: Sequence enforces Next FY & Period 1 activation to `OPEN` status before issuing `OpeningBalanceCapability` and posting `OPENING_BALANCE` journal. |
| **HIGH-04** | Potential partial commits between period close, P&L close, and FY lock during Year-End. | **HIGH** | Section F Boundaries | **RESOLVED**: Enforced single atomic DB transaction spanning the entire 20-step Year-End workflow. Any failure causes 100% `ROLLBACK`. |
| **HIGH-05** | Missing database uniqueness constraint on period closing rates per currency pair. | **HIGH** | Section G Schema | **RESOLVED**: Added `UNIQUE(company_id, closing_operation_id, from_currency_code, to_currency_code)` constraint and `CHECK(from_currency_code != to_currency_code)`. |
| **HIGH-06** | Missing physical composite tenant foreign keys on financial relationship schema. | **HIGH** | Section G Schema | **RESOLVED**: Added physical composite FKs `FOREIGN KEY (company_id, fk_id) REFERENCES parent_table(company_id, id)` across all 8 tables. |

---

## 3. ARCHITECTURAL DECISIONS

1. **Year-End vs Final Period Closure**: Year-End Close is a higher-order atomic workflow. It transitions the final period to `CLOSING`, posts FX revaluation under `PeriodCloseFxCapability`, posts the Year-End P&L closing journal under `YearEndCloseCapability` *while the final period is in `CLOSING`*, posts the Opening Balance journal into Period 1 of Next FY under `OpeningBalanceCapability`, builds the Opening Boundary projection, reconciles balances, persists `financial_fiscal_year_closing_records`, and finally transitions the final period to `CLOSED` and the Fiscal Year to `LOCKED`.
2. **Period Closing Operation (`PeriodClosingOperation`)**: Introduced `financial_period_closing_operations` as the execution identity (`INITIATED`, `IN_PROGRESS`, `COMPLETED`, `FAILED`, `ABORTED`). Rates (`financial_period_closing_rates`) reference `closing_operation_id`. The Completed Fact (`financial_period_closing_records`) references `closing_operation_id`.
3. **Completed Close Fact (`financial_period_closing_records`)**: Immutable record representing successful period close completion. Unique per `(company_id, period_id)`.
4. **Closing Rate Snapshot (`financial_period_closing_rates`)**: Persists user-confirmed rates using `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale). Bound to `closing_operation_id`.
5. **Fiscal Year Closing Fact (`financial_fiscal_year_closing_records`)**: Immutable record representing successful Year-End Close completion. Unique per `(company_id, fiscal_year_id)`.
6. **Opening Balance Journal**: Real authoritative `JournalEntry` posted into Period 1 of Next FY with immutable classification `voucherType = 'opening_balance'`.
7. **Opening Boundary Projection (`financial_fiscal_year_opening_boundaries`)**: Derived performance projection snapshot representing permanent account opening balances for a fiscal year.
8. **Query Model A Selection**: `CurrentYearBalance(FY) = OpeningBoundary(FY) + CurrentYearMovements(FY EXCLUDING voucherType = 'opening_balance')`.
9. **Fiscal Year Overlap & Period Coverage**: FYs must not overlap. Periods within an FY must provide contiguous coverage (`Period N.endDate + 1 day = Period N+1.startDate`) spanning `FY.startDate` through `FY.endDate`.
10. **Next FY Period 1 State & Activation**: Model A Year-End workflow creates Next FY and Period 1, activates them to `OPEN` state, and then posts the `OPENING_BALANCE` journal.
11. **State Machine Consistency**:
    - Fiscal Period: `DRAFT` $\rightarrow$ `OPEN` $\rightarrow$ `CLOSING` $\rightarrow$ `CLOSED` $\rightarrow$ `LOCKED`. `CLOSED` $\rightarrow$ `REOPENED` $\rightarrow$ `CLOSING`.
    - Fiscal Year: `DRAFT` $\rightarrow$ `OPEN` $\rightarrow$ `CLOSED` $\rightarrow$ `LOCKED`. `LOCKED` is irreversible.
12. **Retention & Deletion Policy**: `NO DELETE AFTER CREATION / USE` for all financial evidence tables. `ON DELETE CASCADE` is strictly forbidden for financial evidence.
13. **Idempotency**: Retrying a completed period or year-end close returns the existing completed record without duplicating journal entries.

---

## 4. GATE-08 V3 COMPLETE SPECIFICATION

### 4.1 Financial Document Temporal Coupling & Period Resolution
- Business Master Data (Customer, Supplier, Product, Warehouse, Cash Box, Account, Subject, Currency, Rate Master) DOES NOT require a Fiscal Period.
- Financial Documents (Sales Invoice, Purchase Invoice, Receipt, Payment, Expense, Journal Voucher, Financial Stock Movement, Credit Note, Debit Note, Adjustment, Transfer) MUST be assigned a valid `postingDate` upon creation (defaulting to active business date), which MUST resolve to an operational Fiscal Period (`OPEN` or `REOPENED`).
- Missing period raises `PERIOD_NOT_FOUND`. `DRAFT` periods raise `PERIOD_NOT_OPERATIONAL`. `CLOSED`/`LOCKED` periods raise `PERIOD_CLOSED`.
- Model B (Posting Date Model) is enforced: `documentDate` is commercial/mutable in draft; `postingDate` determines accounting period, ledger placement, and FX snapshot scope, becoming **100% IMMUTABLE** upon posting.
- Resolution via `resolvePeriod(companyId, postingDate)`: 0 rows $\implies$ `PERIOD_NOT_FOUND`; 1 row $\implies$ Success; $>1$ rows $\implies$ `PERIOD_AMBIGUOUS`. Caller-supplied `periodId` override is IGNORED.

### 4.2 Posting Authorization & Controlled Capabilities
- Invariant `FP-INV-07`: Posting authorization has no validity outside the transaction committing the `JournalEntry`.
- `AuthorizationContext` is an internal domain capability object issued exclusively by domain services:
  - `NormalPostingCapability`: Issued for standard business transactions when period is `OPEN` or `REOPENED`.
  - `PeriodCloseFxCapability`: Issued exclusively by `PeriodClosingService` during period close in `CLOSING` state.
  - `YearEndCloseCapability`: Issued exclusively by `YearEndClosingService` during year-end close in `CLOSING` state.
  - `OpeningBalanceCapability`: Issued exclusively by `YearEndClosingService` during Next FY initialization in `OPEN` state.
- `PostingEngine` rejects any journal submission lacking a valid domain capability object.

### 4.3 Period Close & FX Revaluation Workflow
1. User prompt explicitly asks: `Close period with FX revaluation? [YES] [NO]`.
2. Initiates a `PeriodClosingOperation` in `INITIATED` status.
3. If FX revaluation selected:
   - Identifies eligible foreign-currency monetary accounts (Customer/Supplier foreign balances, Foreign Cash/Bank accounts).
   - Collects user-confirmed closing rates for period `endDate`. Missing required rate aborts operation (`FX_REVALUATION_RATE_MISSING`).
   - Persists rates as scaled integers ($10^8$ scale) in `financial_period_closing_rates` referencing `closing_operation_id`.
   - Obtains `PeriodCloseFxCapability` and posts FX revaluation journal (`voucherType = 'period_fx'`) via `PostingEngine`.
4. Persists completed fact in `financial_period_closing_records` referencing `closing_operation_id`.
5. Updates period status from `CLOSING` to `CLOSED`.
6. Updates operation status to `COMPLETED`.

### 4.4 Deterministic 20-Step Year-End Closing Sequence (Model A)
1. Verify Fiscal Year exists and active `companyId` context matches.
2. Verify contiguous period coverage (`Period N.endDate + 1 day = Period N+1.startDate`) spanning `FY.startDate` through `FY.endDate`.
3. Identify final period of the fiscal year.
4. If final period is `OPEN` or `REOPENED`, Year-End workflow internally transitions it to `CLOSING`.
5. Verify ALL child periods are in `CLOSING` or `CLOSED` state.
6. Perform Year-End preflight check (verify ZERO unposted drafts affecting the fiscal year).
7. Calculate final year-end P&L account balances.
8. Resolve `Retained Earnings` account via Account Resolution (GATE-05/06).
9. Post Year-End P&L Closing Journal Entry (`voucherType = 'year_end_close'`) via `PostingEngine` using `YearEndCloseCapability` *while final period is in `CLOSING`*. P&L balances reset to 0.
10. Calculate permanent account (Balance Sheet) carry-forward balances.
11. Create Next Fiscal Year record in `DRAFT` status.
12. Create Next Fiscal Year Period 1 record in `DRAFT` status.
13. Activate Next Fiscal Year and Period 1 to `OPEN` status.
14. Issue `OpeningBalanceCapability` and post Opening Balance Journal Entry (`voucherType = 'opening_balance'`) into Period 1 of Next FY via `PostingEngine`.
15. Build Next Fiscal Year Opening Boundary Projection (`financial_fiscal_year_opening_boundaries`).
16. Reconcile previous year closing balances vs next year opening boundary (`FISCAL_YEAR_OPENING_BALANCE_MISMATCH`).
17. Persist immutable `financial_fiscal_year_closing_records` row referencing year-end closing journal and opening balance journal.
18. Set current Fiscal Year status to `LOCKED`.
19. Set ALL child periods of current FY to `LOCKED`.
20. Commit atomic DB transaction.

### 4.5 Reporting Query Model & Double-Counting Prevention
- Single source of truth: `JournalEntries` + `JournalLines`.
- `FiscalYearOpeningBoundary` is a derived performance projection snapshot.
- Query Model A:
  $$\text{CurrentYearBalance}(FY) = \text{OpeningBoundary}(FY) + \sum \text{JournalLines}(FY \text{ EXCLUDING } \text{voucherType} = \text{'opening\_balance'})$$
- Current-year reporting query boundary: `postingDate >= FY.startDate AND postingDate <= FY.endDate`. Historical closed-year lines are NOT scanned for current-year reports.

---

## 5. DATABASE CONTRACT (`packages/financial`)

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
    CONSTRAINT fk_fp_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT chk_fp_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_fp_comp_id ON financial_fiscal_periods(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_fp_comp_fy_num ON financial_fiscal_periods(company_id, fiscal_year_id, period_number);
CREATE INDEX IF NOT EXISTS idx_fp_comp_dates ON financial_fiscal_periods(company_id, start_date, end_date);

-- 3. Period Closing Operations Table (Execution Identity)
CREATE TABLE IF NOT EXISTS financial_period_closing_operations (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    status TEXT NOT NULL CHECK(status IN ('initiated', 'in_progress', 'completed', 'failed', 'aborted')),
    close_with_fx INTEGER NOT NULL CHECK(close_with_fx IN (0, 1)),
    initiated_at INTEGER NOT NULL,
    completed_at INTEGER,
    initiated_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_pco_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pco_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_pco_comp_period ON financial_period_closing_operations(company_id, period_id);

-- 4. Period Closing Records Table (Completed Fact)
CREATE TABLE IF NOT EXISTS financial_period_closing_records (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    closing_operation_id TEXT NOT NULL CHECK(length(closing_operation_id) = 36),
    closing_date INTEGER NOT NULL,
    fx_revaluation_executed INTEGER NOT NULL DEFAULT 0,
    journal_entry_id TEXT CHECK(journal_entry_id IS NULL OR length(journal_entry_id) = 36),
    created_by TEXT,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_operation FOREIGN KEY (company_id, closing_operation_id) REFERENCES financial_period_closing_operations(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pcr_comp_period ON financial_period_closing_records(company_id, period_id);

-- 5. Period Closing Attempts Table (Audit Log of Failures)
CREATE TABLE IF NOT EXISTS financial_period_closing_attempts (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    closing_operation_id TEXT CHECK(closing_operation_id IS NULL OR length(closing_operation_id) = 36),
    attempted_at INTEGER NOT NULL,
    status TEXT NOT NULL CHECK(status IN ('failed', 'aborted')),
    failure_reason TEXT NOT NULL,
    attempted_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_pca_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pca_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_pca_operation FOREIGN KEY (company_id, closing_operation_id) REFERENCES financial_period_closing_operations(company_id, id) ON DELETE RESTRICT
);

-- 6. Period Closing Rates Snapshot Table (Scaled Integer Rates 10^8)
CREATE TABLE IF NOT EXISTS financial_period_closing_rates (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    closing_operation_id TEXT NOT NULL CHECK(length(closing_operation_id) = 36),
    from_currency_code TEXT NOT NULL,
    to_currency_code TEXT NOT NULL,
    exchange_rate_scaled INTEGER NOT NULL CHECK(exchange_rate_scaled > 0), -- Scaled 10^8
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_rate_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_rate_operation FOREIGN KEY (company_id, closing_operation_id) REFERENCES financial_period_closing_operations(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT chk_rates_different_currencies CHECK(from_currency_code != to_currency_code)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_pcr_rates_op_pair ON financial_period_closing_rates(company_id, closing_operation_id, from_currency_code, to_currency_code);

-- 7. Fiscal Year Closing Records Table (Completed Fact)
CREATE TABLE IF NOT EXISTS financial_fiscal_year_closing_records (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    final_period_id TEXT NOT NULL CHECK(length(final_period_id) = 36),
    next_fiscal_year_id TEXT NOT NULL CHECK(length(next_fiscal_year_id) = 36),
    year_end_journal_id TEXT NOT NULL CHECK(length(year_end_journal_id) = 36),
    opening_balance_journal_id TEXT NOT NULL CHECK(length(opening_balance_journal_id) = 36),
    closed_at INTEGER NOT NULL,
    closed_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fycr_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_fycr_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_fycr_final_period FOREIGN KEY (company_id, final_period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_fycr_next_fy FOREIGN KEY (company_id, next_fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_fycr_comp_fy ON financial_fiscal_year_closing_records(company_id, fiscal_year_id);

-- 8. Fiscal Year Opening Boundaries Table (Derived Projection)
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
    CONSTRAINT fk_ob_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_ob_account FOREIGN KEY (company_id, account_id) REFERENCES financial_accounts(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_ob_comp_fy_acc_subj ON financial_fiscal_year_opening_boundaries(company_id, fiscal_year_id, account_id, IFNULL(subject_id, ''), currency_code);
```

---

## 6. STATE MACHINE CONTRACT

### 6.1 Fiscal Period State Transitions

| From State | To State | Trigger / Condition | Authority / Permission |
| :--- | :--- | :--- | :--- |
| **Initial** | `DRAFT` | Period structure creation | System / FY Creation |
| `DRAFT` | `OPEN` | Operational activation | `accounting.periods.manage` |
| `OPEN` | `CLOSING` | Period Close or Year-End Close initiated | `PeriodClosingService` / `YearEndClosingService` |
| `CLOSING` | `CLOSED` | Period Close or Year-End Close completed | Atomic DB Commit |
| `CLOSING` | `OPEN` / `REOPENED`| Close workflow failure / rollback | Atomic Transaction Rollback |
| `CLOSED` | `REOPENED` | Reopen period request | `accounting.periods.reopen` + Reason + Audit |
| `REOPENED` | `CLOSING` | Re-close workflow initiated | `PeriodClosingService` / `YearEndClosingService` |
| `CLOSED` | `LOCKED` | Year-End Close completed | `YearEndClosingService` (Atomic DB Commit) |
| `LOCKED` | *Any* | **FORBIDDEN** | **NONE (Irreversible)** |

### 6.2 Fiscal Year State Transitions

| From State | To State | Trigger / Condition | Authority / Permission |
| :--- | :--- | :--- | :--- |
| **Initial** | `DRAFT` | Fiscal Year structure creation | System / Admin |
| `DRAFT` | `OPEN` | Fiscal Year activation | `accounting.fiscal_years.manage` |
| `OPEN` | `CLOSED` | All child periods closed | FY Closing Preflight |
| `CLOSED` | `LOCKED` | 20-step Year-End Close completed | `YearEndClosingService` (Atomic DB Commit) |
| `OPEN` | `LOCKED` | 20-step Year-End Close completed | `YearEndClosingService` (Atomic DB Commit) |
| `LOCKED` | *Any* | **FORBIDDEN** | **NONE (Irreversible)** |

---

## 7. TRANSACTION CONTRACT

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
    ├── Assert period.status IN ('OPEN', 'REOPENED') & zero unposted drafts
    ├── Create PeriodClosingOperation in 'initiated' status
    ├── UPDATE financial_fiscal_periods SET status = 'closing'
    ├── IF closeWithFxRevaluation = true:
    │     ├── Validate all required closing rates exist
    │     ├── Persist scaled rates into financial_period_closing_rates (ref operation_id)
    │     ├── Obtain PeriodCloseFxCapability
    │     └── PostingEngine.post(fxJournal, capability)
    ├── Persist completed fact into financial_period_closing_records (ref operation_id)
    ├── UPDATE financial_period_closing_operations SET status = 'completed'
    ├── UPDATE financial_fiscal_periods SET status = 'closed'
COMMIT ATOMIC DB TRANSACTION

3. YEAR-END CLOSE TRANSACTION BOUNDARY (MODEL A):
BEGIN ATOMIC DB TRANSACTION
    ├── Assert contiguous period coverage & zero unposted drafts in FY
    ├── Identify final period; IF OPEN/REOPENED -> transition to 'closing'
    ├── Obtain YearEndCloseCapability
    ├── PostingEngine.post(yearEndCloseJournal, capability) -> zero P&L (while final period is 'closing')
    ├── Calculate permanent account carry-forward balances
    ├── Create Next FY & Period 1 records in 'draft' status
    ├── UPDATE Next FY & Period 1 SET status = 'open'
    ├── Obtain OpeningBalanceCapability
    ├── PostingEngine.post(openingBalanceJournal, capability) into Next Period 1
    ├── Build financial_fiscal_year_opening_boundaries projection snapshot
    ├── Reconcile closing balances vs opening boundaries
    ├── Persist financial_fiscal_year_closing_records
    ├── UPDATE current FY SET status = 'locked'
    ├── UPDATE current FY child periods SET status = 'locked'
COMMIT ATOMIC DB TRANSACTION
```

---

## 8. INVARIANT MATRIX (`FP-INV-01..38`)

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
| **FP-INV-34** | Opening Balance Journal requires existing operational Next Period 1. | Year-End Service | Post opening journal without period |
| **FP-INV-35** | Reopening period requires permission, reason, and audit event. | Audit System | Reopen without reason |
| **FP-INV-36** | Closed-period reversal posts into active period with new date. | Reversal Service | Reversal in closed period |
| **FP-INV-37** | Historical closed-year lines isolated from current year queries. | Reporting Engine | Query current year balances |
| **FP-INV-38** | Rebuilding Opening Boundary produces identical balances. | Rebuild Utility | Rebuild boundary from history |

---

## 9. ADVERSARIAL TEST MATRIX (`ATTACK-FP-01..38`)

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
| **ATTACK-FP-13** | Year-End Close attempted while final period is `OPEN`. | ALLOWED (Orchestrated) | Success (Atomic Year-End) | Year-End Service |
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
| **ATTACK-FP-34** | Post opening balance journal in a `DRAFT` period. | REJECT | `PERIOD_NOT_OPERATIONAL` | `PostingEngine` |
| **ATTACK-FP-35** | Query historical year report using current year boundary. | REJECT | `HISTORICAL_QUERY_INVALID` | Reporting Engine |
| **ATTACK-FP-36** | Attempt period close with zero periods defined in FY. | REJECT | `FISCAL_YEAR_EMPTY` | Preflight Check |
| **ATTACK-FP-37** | Modifying exchange rate master data after FX snapshot creation. | Historical Immutable | Historical Entry Unchanged | Snapshot Table |
| **ATTACK-FP-38** | Attempt to reuse `PeriodCloseFxCapability` outside close transaction.| REJECT | `CAPABILITY_EXPIRED` | Domain Capability |

---

## 10. LEGACY REPLACEMENT MATRIX

| Current Legacy Mechanism | Replacement Architecture | Implementation-Phase Removal Requirement |
| :--- | :--- | :--- |
| `accounting_fiscal_closed_through` setting | Explicit company-scoped `financial_fiscal_periods` table. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove setting lookup). |
| Tenantless `findPeriodContaining` | `FinancialPeriodResolver.resolve(companyId, postingDate)`. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove tenantless method). |
| In-memory `FiscalPeriodPolicy` | Domain `FinancialPeriodGate` executing inside DB transaction. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove in-memory policy). |
| Inline module date checks in Sales/Purchases | Standardized call to canonical Posting Gate. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove inline checks). |
| Null-company `AccountingPeriodsCompanion` | Mandatory `company_id TEXT NOT NULL` schema contract. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove null-company support). |
| Floating-point exchange rates in DB | `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale). | **REQUIRED FOR IMPLEMENTATION PHASE** (Migrate schema column). |

---

## 11. FINAL SELF-AUDIT (30 CONSISTENCY QUESTIONS)

1. Can a financial document exist without a valid operational Fiscal Period? $\rightarrow$ **NO**
2. Can a caller inject a periodId and override postingDate resolution? $\rightarrow$ **NO**
3. Can normal posting occur in CLOSING? $\rightarrow$ **NO**
4. Can Year-End Close post its controlled Year-End Journal while final period is CLOSING? $\rightarrow$ **YES**, exclusively through internal `YearEndCloseCapability`.
5. Can Year-End Journal post after the final period has already become CLOSED? $\rightarrow$ **NO**
6. Can closing rates exist without a valid closing operation? $\rightarrow$ **NO**
7. Can closing rates be persisted before the completed close fact? $\rightarrow$ **YES**, bound to `closing_operation_id`.
8. Can a failed close prevent retry? $\rightarrow$ **NO**
9. Can two completed close facts exist for the same company + period? $\rightarrow$ **NO**
10. Can two FX rates exist for the same currency pair in one close operation? $\rightarrow$ **NO**
11. Can Fiscal Years overlap within a company? $\rightarrow$ **NO**
12. Can a Fiscal Period exist outside its Fiscal Year? $\rightarrow$ **NO**
13. Can required period coverage contain undefined gaps at Year-End? $\rightarrow$ **NO**
14. Can Opening Balance Journal be posted into a DRAFT Period 1? $\rightarrow$ **NO**
15. Is Period 1 operational before Opening Balance posting? $\rightarrow$ **YES**
16. Can Opening Boundary and Opening Balance Journal double-count? $\rightarrow$ **NO**
17. Can Opening Boundary be deterministically rebuilt? $\rightarrow$ **YES**
18. Is `opening_balance` a canonical journal classification? $\rightarrow$ **YES**
19. Can a current-year report scan previous closed years? $\rightarrow$ **NO**
20. Can a closed period be reopened after its Fiscal Year is LOCKED? $\rightarrow$ **NO**
21. Can a locked Fiscal Year be reopened? $\rightarrow$ **NO**
22. Can immutable financial closing evidence be deleted through cascade? $\rightarrow$ **NO**
23. Can cross-company closing records be referenced? $\rightarrow$ **NO**
24. Can Year-End partially commit? $\rightarrow$ **NO**
25. Can duplicate Year-End Close create duplicate Opening Journals? $\rightarrow$ **NO**
26. Can duplicate Period Close create duplicate FX journals? $\rightarrow$ **NO**
27. Does every referenced database entity exist in the physical schema contract? $\rightarrow$ **YES**
28. Does every claimed physical FK actually exist? $\rightarrow$ **YES**
29. Are GATE-01..07 unchanged? $\rightarrow$ **YES**
30. Is implementation still prohibited? $\rightarrow$ **YES**

---

## 12. FINAL VERDICT

```text
NEXABIZ ERP — GATE-08 V3

DESIGN STATUS: FROZEN

IMPLEMENTATION STATUS: NOT STARTED

DATABASE MIGRATIONS: NOT STARTED

TEST IMPLEMENTATION: NOT STARTED

GATE-01..07: CLOSED / LOCKED / UNCHANGED

AUTHORITY: READY FOR IMPLEMENTATION PHASE
```
