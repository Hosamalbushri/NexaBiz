# NEXABIZ ERP — GATE-08 V4
# FISCAL PERIOD + FX REVALUATION + FISCAL YEAR CLOSING ARCHITECTURE SPECIFICATION & DESIGN FREEZE

> **DOCUMENT STATUS: DESIGN FROZEN V4**  
> **IMPLEMENTATION STATUS: NOT STARTED (STRICTLY PROHIBITED IN GATE-08 V4 REVISION PHASE)**  
> **DATABASE MIGRATIONS: NOT STARTED**  
> **GATE-01..07 STATUS: CLOSED AND LOCKED (FROZEN CONTRACTS)**

---

## 1. EXECUTIVE ARCHITECTURE

NexaBiz ERP GATE-08 V4 establishes the canonical financial architecture for Fiscal Periods, Period Closing Operations, FX Revaluation, Year-End Closing Workflows, and Opening Balance Boundaries.

```text
GATE-08 V4 — DESIGN FROZEN

Implementation Status: NOT STARTED
Database Changes: NOT STARTED
Migration: NOT STARTED
Tests Implementation: NOT STARTED
```

### Core Architecture Pipeline:
```text
Financial Document
      ↓
postingDate
      ↓
Fiscal Period
      ↓
Period Authorization
      ↓
PostingEngine
      ↓
JournalEntry / JournalLines
      ↓
Period Close Operation
      ↓
FX Revaluation
      ↓
Period CLOSED
      ↓
Fiscal Year Close
      ↓
Opening Balance Journal
      ↓
Next Fiscal Year & Opening Boundary
```

---

## 2. SCOPE AND FROZEN DEPENDENCIES

GATE-01 through GATE-07 are CLOSED, LOCKED, and IMMUTABLE. GATE-08 V4 preserves all frozen contracts:
- Canonical monetary representation (`DecimalMoney` / scaled `Int64` $10^8$ scale).
- Canonical rate representation (`DecimalRate` / scaled `Int64` $10^8$ scale).
- Zero `REAL`/`FLOAT`/`DOUBLE` database storage for financial quantities.
- Stable technical account identity (`FinancialAccount.id` UUID v7). `FinancialAccount.code` is a mutable human-readable reference.
- Account Resolution precedence (GATE-05/GATE-06 Context Hierarchy).
- `PostingEngine` is the sole authorized writer of `JournalEntry` and `JournalLine` ledgers.
- Multi-company composite tenant isolation (`company_id` enforced on every financial entity).
- Customer/Supplier dedicated financial accounts (`AccountingSubject.primaryAccountId`).

---

## 3. FISCAL YEAR MODEL

A Fiscal Year (`financial_fiscal_years`) represents a company-scoped temporal accounting boundary.
- **Identity**: `id` UUID v7 (36-char string), `company_id` UUID v7.
- **Properties**: `code`, `name`, `start_date` (UTC epoch ms), `end_date` (UTC epoch ms), `status`.
- **Temporal Integrity**:
  1. `start_date <= end_date`.
  2. No temporal overlap between Fiscal Years within the same company ($\neg \exists FY : FY.\text{startDate} \le \text{newEndDate} \land FY.\text{endDate} \ge \text{newStartDate}$).
  3. Contiguous coverage: Child periods must span `FY.start_date` to `FY.end_date` without gaps (`Period N.end_date + 1 day = Period N+1.start_date`).

---

## 4. FISCAL PERIOD MODEL

A Fiscal Period (`financial_fiscal_periods`) represents an operational posting window within a Fiscal Year.
- **Identity**: `id` UUID v7, `company_id` UUID v7, `fiscal_year_id` UUID v7, `period_number` (1..N).
- **Properties**: `name`, `start_date`, `end_date`, `status`.
- **Containment**: `FP.start_date >= FY.start_date AND FP.end_date <= FY.end_date`.
- **Non-Overlap**: No overlapping periods within the same company.
- **Unique Constraint**: `UNIQUE(company_id, fiscal_year_id, period_number)`.

---

## 5. POSTING DATE CONTRACT

1. **Master Data Independence**: Business Master Data (Customer, Supplier, Product, Warehouse, Cash Box, Account, Subject) requires no Fiscal Period.
2. **Document Temporal Coupling**: Every Financial Document must be assigned a `postingDate` upon creation.
3. **Resolution Rule**: `resolvePeriod(companyId, postingDate)` strictly determines the operational Fiscal Period.
   - 0 matches $\implies$ `PERIOD_NOT_FOUND`.
   - 1 match $\implies$ Valid Period.
   - $>1$ matches $\implies$ `PERIOD_AMBIGUOUS`.
4. **Draft vs Operational**: `DRAFT` period raises `PERIOD_NOT_OPERATIONAL`. `CLOSED`/`LOCKED` period raises `PERIOD_CLOSED`.
5. **Immutability**: `postingDate` determines period placement and exchange rate scope, becoming **100% IMMUTABLE** upon posting. Caller-supplied `periodId` override is strictly IGNORED.

---

## 6. PERIOD STATE MACHINE

```text
DRAFT ──► OPEN ──► CLOSING ──► CLOSED ──► LOCKED
                     ▲           │
                     │           ▼
                     └─── REOPENED
```

### Legal Transitions:
- `DRAFT` $\rightarrow$ `OPEN`: Operational activation.
- `OPEN` $\rightarrow$ `CLOSING`: Period close or Year-End workflow initiated.
- `CLOSING` $\rightarrow$ `CLOSED`: Close workflow completion (commit).
- `CLOSING` $\rightarrow$ `OPEN`/`REOPENED`: Workflow failure (transaction rollback).
- `CLOSED` $\rightarrow$ `REOPENED`: Reopen request (requires permission `accounting.periods.reopen` + audit reason).
- `REOPENED` $\rightarrow$ `CLOSING`: Re-close workflow initiated.
- `CLOSED` $\rightarrow$ `LOCKED`: Year-End Close completed.

### Forbidden Transitions:
- `CLOSING` $\rightarrow$ `LOCKED` (MUST become `CLOSED` first).
- `OPEN` $\rightarrow$ `LOCKED` (MUST become `CLOSED` first).
- `DRAFT` $\rightarrow$ `CLOSED` / `LOCKED`.
- `CLOSED` $\rightarrow$ `CLOSING` (MUST become `REOPENED` first).
- `LOCKED` $\rightarrow$ *Any* (**IRREVERSIBLE**).

---

## 7. FISCAL YEAR STATE MACHINE

```text
DRAFT ──► OPEN ──► CLOSED ──► LOCKED
```

### Legal Transitions:
- `DRAFT` $\rightarrow$ `OPEN`: Fiscal Year activation.
- `OPEN` $\rightarrow$ `CLOSED`: All child periods are in `CLOSED` state and Year-End workflows complete.
- `CLOSED` $\rightarrow$ `LOCKED`: Year-End finalization complete.

### Forbidden Transitions:
- `OPEN` $\rightarrow$ `LOCKED` (**STRICTLY FORBIDDEN**; must pass through `CLOSED`).
- `DRAFT` $\rightarrow$ `CLOSED` / `LOCKED`.
- `LOCKED` $\rightarrow$ *Any* (**IRREVERSIBLE**).

---

## 8. PERIOD CLOSING OPERATION (`PeriodClosingOperation`)

Introduced `financial_period_closing_operations` as the explicit execution identity for period closing.
- **Lifecycle**: `INITIATED` $\rightarrow$ `IN_PROGRESS` $\rightarrow$ `COMPLETED` / `FAILED` / `ABORTED`.
- **Durable Identity**: Operation ID is created prior to atomic financial mutations to ensure failure audit trail durability.
- **Completed Fact**: `financial_period_closing_records` is persisted upon successful completion, referencing `closing_operation_id`.
- **Failed Evidence**: `financial_period_closing_attempts` logs failure details referencing `closing_operation_id`.

---

## 9. FX REVALUATION

Period Close prompts: `Do you want to perform FX revaluation before closing the final fiscal period? [YES] [NO]`.
- **Eligibility**: Foreign-currency monetary accounts (Bank, Cash, Customer/Supplier foreign sub-ledgers). Revenue/Expense P&L accounts excluded.
- **Rates Snapshot**: User-confirmed closing exchange rates persisted in `financial_period_closing_rates` using `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale) referencing `closing_operation_id`.
- **Capability**: Issued `PeriodCloseFxCapability` authorizes `PostingEngine` to post the FX revaluation journal entry (`voucherType = 'period_fx'`).

---

## 10. PERIOD CLOSING EVIDENCE

Every period close generates immutable evidence:
1. `financial_period_closing_operations` (Execution metadata).
2. `financial_period_closing_rates` (Immutable scaled FX rates snapshot).
3. `JournalEntry` / `JournalLine` (FX revaluation journal, if revaluation executed).
4. `financial_period_closing_records` (Immutable completed fact).

---

## 11. CANONICAL YEAR-END CLOSE WORKFLOW

Year-End Close is a higher-order atomic workflow orchestrating final period closure, P&L closure, and Next FY initialization.

### PHASE A — PRE-FLIGHT
1. Verify company context.
2. Verify Fiscal Year status == `OPEN`.
3. Verify temporal integrity & non-overlap.
4. Verify contiguous period coverage (`Period N.end_date + 1 day = Period N+1.start_date`).
5. Verify ALL child periods belong to this Fiscal Year.
6. Resolve final period.
7. **REJECT** if final period == `CLOSED` (`YEAR_END_FINAL_PERIOD_ALREADY_CLOSED`). User must explicitly `REOPEN` first.
8. **REJECT** if final period == `LOCKED`.
9. Verify ZERO unposted financial drafts in FY.
10. Explicitly query user for FX revaluation choice (`YES`/`NO`).

### PHASE B — ENTER FINAL PERIOD CLOSING
- Final period (`OPEN` or `REOPENED`) transitions to `CLOSING` via canonical `PeriodClosingOperation`.

### PHASE C — FX REVALUATION (IF REQUESTED)
- Snapshot closing rates $\rightarrow$ `financial_period_closing_rates` (scaled $10^8$).
- Obtain `PeriodCloseFxCapability` $\rightarrow$ Post FX journal via `PostingEngine`.

### PHASE D — P&L CLOSING
- Calculate temporary account balances (Revenue, Expense, COGS).
- Resolve `Retained Earnings` account.
- Obtain internal `YearEndCloseCapability` $\rightarrow$ Post Year-End P&L Journal Entry (`voucherType = 'year_end_close'`) *while final period is in `CLOSING`*. P&L balances reset to 0.

### PHASE E — FINAL PERIOD CLOSURE
- Final period transitions `CLOSING` $\rightarrow$ `CLOSED`.
- Persist `financial_period_closing_records` (Completed Fact).

### PHASE F — VERIFY ALL PERIODS CLOSED
- Assert `∀ period ∈ FY : period.status == CLOSED`. If any period is `OPEN`/`CLOSING`/`REOPENED`, abort.

### PHASE G — FISCAL YEAR CLOSURE
- Fiscal Year transitions `OPEN` $\rightarrow$ `CLOSED`.

### PHASE H — NEXT FISCAL YEAR INITIALIZATION
- Create Next FY in `DRAFT` status.
- Create Next FY Period 1 in `DRAFT` status.
- Activate Next FY (`DRAFT` $\rightarrow$ `OPEN`) and Period 1 (`DRAFT` $\rightarrow$ `OPEN`).
- Obtain `OpeningBalanceCapability` $\rightarrow$ Post Opening Balance Journal Entry (`voucherType = 'opening_balance'`) into operational Period 1 of Next FY via `PostingEngine`.
- Build Next FY Opening Boundary projection (`financial_fiscal_year_opening_boundaries`).
- Reconcile previous FY ending balances vs Next FY opening boundary (`FISCAL_YEAR_OPENING_BALANCE_MISMATCH`).
- Persist `financial_fiscal_year_closing_records` referencing `year_end_journal_id` and `opening_balance_journal_id`.

### PHASE I — FINAL LOCK
- All child periods transition `CLOSED` $\rightarrow$ `LOCKED`.
- Current Fiscal Year transitions `CLOSED` $\rightarrow$ `LOCKED`.
- Commit atomic DB transaction.

---

## 12. FINAL PERIOD CLOSURE

Year-End Close MUST explicitly execute the `CLOSING` $\rightarrow$ `CLOSED` transition for the final period and persist `financial_period_closing_records` BEFORE the Fiscal Year transitions to `CLOSED`. Direct transition from `CLOSING` to `LOCKED` is strictly forbidden.

---

## 13. P&L CLOSING

Year-End P&L journal closes all temporary revenue and expense accounts into Retained Earnings.
- Issued capability: `YearEndCloseCapability`.
- Executed exclusively while final period is in `CLOSING` state.
- Classification: `voucherType = 'year_end_close'`.

---

## 14. RETAINED EARNINGS

The Retained Earnings account is resolved via canonical Account Resolution (GATE-05/06). The net income/loss from P&L accounts is posted to this account.

---

## 15. NEXT FISCAL YEAR

Created as `DRAFT`, Period 1 created as `DRAFT`. Activated to `OPEN` state prior to Opening Balance Journal posting to ensure operational period validity.

---

## 16. OPENING BALANCE JOURNAL

Authoritative `JournalEntry` posted into Period 1 of Next FY.
- Immutable classification: `voucherType = 'opening_balance'`.
- Authoritative financial lines carrying forward permanent asset, liability, and equity balances.
- P&L account opening balances are strictly 0.

---

## 17. OPENING BOUNDARY

`financial_fiscal_year_opening_boundaries` is a derived performance projection snapshot representing permanent account opening balances.
- Single source of truth: `JournalEntries` + `JournalLines`.
- Query Model A:
  $$\text{CurrentYearBalance}(FY) = \text{OpeningBoundary}(FY) + \sum \text{JournalLines}(FY \text{ EXCLUDING } \text{voucherType} = \text{'opening\_balance'})$$

---

## 18. OPENING BOUNDARY REBUILD

Opening Boundary can be derived deterministically from historical `JournalLines` of prior closed fiscal years.
- Rebuild is an administrative projection repair tool only.
- Does NOT mutate or rewrite `JournalLines`.
- Logs actor identity, timestamp, reason, and validation checksums.

---

## 19. DATABASE SCHEMA (`packages/financial`)

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

-- 7. Fiscal Year Closing Records Table (Completed Fact with Journal FKs)
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
    CONSTRAINT fk_fycr_next_fy FOREIGN KEY (company_id, next_fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_fycr_year_end_journal FOREIGN KEY (company_id, year_end_journal_id) REFERENCES journal_entries(company_id, id) ON DELETE RESTRICT,
    CONSTRAINT fk_fycr_opening_journal FOREIGN KEY (company_id, opening_balance_journal_id) REFERENCES journal_entries(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_fycr_comp_fy ON financial_fiscal_year_closing_records(company_id, fiscal_year_id);

-- 8. Fiscal Year Opening Boundaries Table (Derived Projection Snapshot)
CREATE TABLE IF NOT EXISTS financial_fiscal_year_opening_boundaries (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    account_id TEXT NOT NULL CHECK(length(account_id) = 36),
    subject_id TEXT CHECK(subject_id IS NULL OR length(subject_id) = 36), -- Projection Identity (Validated at Domain Layer)
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

## 20. FOREIGN KEYS AND TENANT ISOLATION

All 8 database tables enforce composite tenant matching via `FOREIGN KEY (company_id, fk_id) REFERENCES parent_table(company_id, id)`. `subject_id` in `financial_fiscal_year_opening_boundaries` is explicitly classified as a projection identity validated for tenant isolation at the domain service layer.

---

## 21. DELETE / ARCHIVE POLICY

Historical financial evidence tables enforce `NO DELETE AFTER CREATION / USE`. `ON DELETE CASCADE` is strictly FORBIDDEN for financial evidence. Deletion attempts raise `ENTITY_LOCKED` or DB RESTRICT foreign key violations.

---

## 22. TRANSACTION BOUNDARIES & TRANSACTION DIAGRAM

```text
PRE-FLIGHT (Validation & FX Prompt)
    │
    ▼
PHASE 1: Durable Operation / Attempt Registration
    │   (Persists PeriodClosingOperation in 'initiated' status)
    ▼
PHASE 2: BEGIN ATOMIC BUSINESS TRANSACTION
    │
    ├── Final Period → CLOSING
    │
    ├── IF FX Requested:
    │     ├── Snapshot Rates -> financial_period_closing_rates
    │     └── Post FX Journal (PeriodCloseFxCapability)
    │
    ├── Post Year-End P&L Journal (YearEndCloseCapability while final period in CLOSING)
    │
    ├── Final Period → CLOSED (Persist financial_period_closing_records)
    │
    ├── Assert ALL Child Periods == CLOSED
    │
    ├── Fiscal Year → CLOSED
    │
    ├── Create Next FY & Period 1 ('draft' -> 'open')
    │
    ├── Post Opening Balance Journal (OpeningBalanceCapability) into Next Period 1
    │
    ├── Build financial_fiscal_year_opening_boundaries projection snapshot
    │
    ├── Reconcile Closing Balances vs Opening Boundaries
    │
    ├── Persist financial_fiscal_year_closing_records
    │
    ├── Fiscal Year → LOCKED
    │
    └── ALL Child Periods → LOCKED
    │
    ▼
PHASE 3: COMMIT ATOMIC BUSINESS TRANSACTION
    │   (UPDATE PeriodClosingOperation -> 'completed')
    ▼
(If Business Transaction Fails: ROLLBACK BUSINESS TRANSACTION while preserving failure log in financial_period_closing_attempts)
```

---

## 23. ROLLBACK AND AUDIT DURABILITY

To ensure failure evidence survives transaction rollbacks, period closing uses a 3-phase execution pattern:
1. **Phase 1**: Register execution identity `PeriodClosingOperation` in a durable pre-transaction.
2. **Phase 2**: Execute financial state changes inside an atomic DB transaction.
3. **Phase 3**: If Phase 2 succeeds, update operation to `COMPLETED` and persist `PeriodClosingRecord`. If Phase 2 fails, rollback financial changes and record failure details in `financial_period_closing_attempts` (`status = 'failed'`).

---

## 24. IDEMPOTENCY

Period Close and Year-End Close are strictly idempotent. Re-submitting a close operation for an already closed period or year returns the existing completed fact (`financial_period_closing_records` or `financial_fiscal_year_closing_records`) without duplicating journal entries.

---

## 25. AUTHORIZATION CAPABILITIES

- `NormalPostingCapability`: Standard business journal posting (`OPEN`/`REOPENED` periods).
- `PeriodCloseFxCapability`: FX revaluation journal posting during period close (`CLOSING` state).
- `YearEndCloseCapability`: Year-End P&L closing journal posting (`CLOSING` state).
- `OpeningBalanceCapability`: Opening balance journal posting into Next Period 1 (`OPEN` state).

---

## 26. INVARIANT MATRIX (`FP-INV-01..50`)

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
| **FP-INV-39** | Fiscal Year cannot transition to `CLOSED` unless ALL child periods are `CLOSED`. | FY State Machine | FY Close with open child period |
| **FP-INV-40** | Fiscal Year cannot transition to `LOCKED` unless it is `CLOSED`. | FY State Machine | Direct `OPEN` -> `LOCKED` attempt |
| **FP-INV-41** | Fiscal Period cannot transition to `LOCKED` unless it is `CLOSED`. | Period State Machine | Direct `CLOSING` -> `LOCKED` attempt |
| **FP-INV-42** | Final-period Year-End cannot start if final period is `CLOSED` or `LOCKED`. | Year-End Service | Year-End with `CLOSED` final period |
| **FP-INV-43** | Final-period Year-End must use canonical `PeriodClosingOperation` evidence. | Year-End Service | Verify closing record creation |
| **FP-INV-44** | Completed `FiscalYearClosingRecord` must reference authoritative Year-End Journal. | DB FK + Service | Null year-end journal ID test |
| **FP-INV-45** | Completed `FiscalYearClosingRecord` must reference authoritative Opening Journal. | DB FK + Service | Null opening journal ID test |
| **FP-INV-46** | Opening Boundary is not an independent source of accounting truth. | Architecture Core | Mutate boundary & verify journals |
| **FP-INV-47** | Failed business transactions must preserve failure audit evidence. | 3-Phase Execution | Simulate rollback & inspect log |
| **FP-INV-48** | Year-End execution is strictly idempotent across repeated requests. | Year-End Service | Re-execute Year-End Close |
| **FP-INV-49** | Zero financial closing evidence rows can be deleted after completion. | DB Restrict FK | Delete closing record attempt |
| **FP-INV-50** | No Year-End workflow may commit partial financial truth. | Transaction Boundary | Fail mid-way & assert rollback |

---

## 27. ADVERSARIAL ATTACK MATRIX (`ATTACK-FP-01..48`)

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
| **ATTACK-FP-39** | Year-End Close attempted while final period is `CLOSED`. | REJECT | `YEAR_END_FINAL_PERIOD_ALREADY_CLOSED` | Year-End Service |
| **ATTACK-FP-40** | Year-End Close attempts direct `OPEN` -> `LOCKED` transition. | REJECT | `INVALID_STATE_TRANSITION` | FY State Machine |
| **ATTACK-FP-41** | Attempt to transition period directly from `CLOSING` -> `LOCKED`.| REJECT | `INVALID_STATE_TRANSITION` | Period State Machine |
| **ATTACK-FP-42** | Fiscal Year `CLOSED` attempted while child period is `CLOSING`. | REJECT | `PERIOD_NOT_CLOSED` | FY State Machine |
| **ATTACK-FP-43** | Year-End Close attempts final period close bypassing operation. | REJECT | `OPERATION_REQUIRED` | Close Service |
| **ATTACK-FP-44** | Business transaction failure loses failure audit evidence. | PREVENTED | 3-Phase Execution Pattern | Execution Architecture |
| **ATTACK-FP-45** | Duplicate Year-End request creates second Opening Balance Journal. | Idempotent Replay | Success (Cached Fact) | Year-End Service |
| **ATTACK-FP-46** | Opening Boundary manually mutated without journal line change. | REJECT | `SNAPSHOT_IMMUTABLE` | DB / Service Layer |
| **ATTACK-FP-47** | Opening Boundary `subject_id` belongs to another company. | REJECT | `CROSS_TENANT_SUBJECT` | Domain Tenant Guard |
| **ATTACK-FP-48** | `FiscalYearClosingRecord` references journal from another company.| REJECT | DB FK Constraint | DB Foreign Key |

---

## 28. LEGACY REMOVAL MATRIX

| Current Legacy Mechanism | Replacement Architecture | Implementation-Phase Removal Requirement |
| :--- | :--- | :--- |
| `accounting_fiscal_closed_through` setting | Explicit company-scoped `financial_fiscal_periods` table. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove setting lookup). |
| Tenantless `findPeriodContaining` | `FinancialPeriodResolver.resolve(companyId, postingDate)`. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove tenantless method). |
| In-memory `FiscalPeriodPolicy` | Domain `FinancialPeriodGate` executing inside DB transaction. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove in-memory policy). |
| Inline module date checks in Sales/Purchases | Standardized call to canonical Posting Gate. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove inline checks). |
| Null-company `AccountingPeriodsCompanion` | Mandatory `company_id TEXT NOT NULL` schema contract. | **REQUIRED FOR IMPLEMENTATION PHASE** (Remove null-company support). |
| Floating-point exchange rates in DB | `exchange_rate_scaled INTEGER NOT NULL` ($10^8$ scale). | **REQUIRED FOR IMPLEMENTATION PHASE** (Migrate schema column). |

---

## 29. MIGRATION / IMPLEMENTATION BOUNDARY

The GATE-08 V4 specification is **100% FROZEN**. No production Dart code, Drift migrations, or database changes shall be executed until Phase 2B implementation phase opens.

---

## 30. FINAL SELF-AUDIT (31 ARCHITECTURAL CHECKBOXES)

- [x] Final Period `CLOSING` $\rightarrow$ `CLOSED` is explicit.
- [x] Fiscal Year `OPEN` $\rightarrow$ `CLOSED` $\rightarrow$ `LOCKED` is explicit.
- [x] No `OPEN` $\rightarrow$ `LOCKED` path exists.
- [x] `CLOSED` final period is rejected by Year-End (`YEAR_END_FINAL_PERIOD_ALREADY_CLOSED`).
- [x] Final Period uses canonical `PeriodClosingOperation`.
- [x] FX YES/NO is explicit during Year-End.
- [x] Closing rates are immutable scaled integers ($10^8$).
- [x] All periods are `CLOSED` before FY closure.
- [x] No `CLOSING` period can become `LOCKED`.
- [x] Opening Balance Journal is canonical (`voucherType = 'opening_balance'`).
- [x] Opening Boundary semantics are frozen (Model A).
- [x] Opening Boundary rebuild semantics are frozen.
- [x] Journal foreign keys are physically specified on `financial_fiscal_year_closing_records`.
- [x] Subject foreign-key semantics are explicit.
- [x] Operation/attempt rollback semantics are explicit (3-phase pattern).
- [x] Failure evidence survives business rollback.
- [x] Business atomicity is explicit.
- [x] Idempotency is explicit.
- [x] No destructive cascade exists on financial evidence.
- [x] GATE-01..07 remain untouched.
- [x] No implementation has started.
- [x] No migration has started.
- [x] No unresolved contradiction remains.

---

## 31. FREEZE VERDICT

```text
GATE-08 V4 — DESIGN FROZEN

IMPLEMENTATION STATUS: NOT STARTED

DATABASE MIGRATIONS: NOT STARTED

TEST IMPLEMENTATION: NOT STARTED

GATE-01..07: CLOSED / LOCKED / UNCHANGED

AUTHORITY: READY FOR IMPLEMENTATION PHASE
```
