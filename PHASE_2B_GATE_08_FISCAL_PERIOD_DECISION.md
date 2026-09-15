# NEXABIZ ERP — PHASE 2B — GATE-08
# FISCAL PERIOD RULES — DESIGN FREEZE SPECIFICATION

> **DOCUMENT STATUS: FROZEN DESIGN ONLY**  
> **IMPLEMENTATION STATUS: PROHIBITED IN GATE-08 DESIGN PHASE**  
> **GATE-07 STATUS: CLOSED AND LOCKED (UNTOUCHED)**

---

## A. EXECUTIVE DECISION

NexaBiz ERP requires a single, authoritative, company-scoped Fiscal Period domain model governing financial accounting eligibility, journal posting validation, period closing workflows, historical immutability, and financial reporting.

### Core Architectural Mandates:
1. **Single Posting Gate**: All financial transactions (Manual Journals, Sales, Purchases, Receipts & Payments, Inventory Movements, Costing Adjustments, FX Revaluations) MUST pass through the unified Financial Core Period Validation Gate before journal generation or posting.
2. **Company Isolation**: Fiscal Years and Fiscal Periods are strictly owned by an authoritative active company (`companyId`). Cross-company period lookups or cross-company period references are strictly rejected (`FISCAL_PERIOD_CROSS_TENANT`).
3. **Posting Date Supremacy**: Financial period belonging and period state eligibility are determined strictly and exclusively by `JournalEntry.postingDate`. Commercial document dates (e.g. vendor invoice date, sale creation timestamp) do not govern ledger period placement.
4. **Immutable Historical Ledgers**: Closing a period blocks new posting and edits in that period date range. Closing NEVER alters, mutates, or rewrites historical posted journals. Reversals for entries in closed periods MUST post into an open period with a current posting date.
5. **Fail-Closed Resolution**: Period resolution for any date outside a defined and `OPEN` (or `REOPENED`) fiscal period MUST fail closed and throw a canonical domain exception (`FISCAL_PERIOD_NOT_FOUND`, `FISCAL_PERIOD_CLOSED`, or `FISCAL_PERIOD_LOCKED`).

---

## B. CANONICAL DOMAIN MODEL

The canonical hierarchy governing accounting periods is:

```text
Company Context (activeCompanyId)
    └── Fiscal Year (FinancialFiscalYear)
          └── Fiscal Period (FinancialFiscalPeriod)
                └── Posting Date (postingDate)
                      └── Posted Journal Entry (JournalEntry)
```

### 1. FinancialFiscalYear
- **Identity**: `id` (UUID v7, 36 chars) — Primary Technical Identity.
- **Code**: `code` (e.g., `FY2026`) — Human-readable identifier (unique per company).
- **Name**: `name` (e.g., `Fiscal Year 2026`).
- **Date Range**: `startDate` to `endDate` (inclusive UTC date-only midnight).
- **Status**: `DRAFT` | `OPEN` | `CLOSED` | `LOCKED`.
- **Base Currency**: `baseCurrencyCode` (e.g., `YER`, `SAR`, `USD`).
- **Period Count**: `periodCount` (e.g., 12).
- **Frequency**: `periodFrequency` (`monthly`).
- **FX Settings**: `fxRevaluationEnabled` (bool), `fxGainAccountId` (UUID v7), `fxLossAccountId` (UUID v7).
- **Audit**: `createdAt`, `updatedAt`, `closedAt`, `createdBy`, `closedBy`.

### 2. FinancialFiscalPeriod
- **Identity**: `id` (UUID v7, 36 chars) — Primary Technical Identity.
- **Parent Reference**: `fiscalYearId` (UUID v7, 36 chars) — FK to `financial_fiscal_years`.
- **Company Identity**: `companyId` (UUID v7, 36 chars) — Foreign key to tenant company.
- **Period Number**: `periodNumber` (1..N).
- **Name**: `name` (e.g., `Period 01 - Jan 2026`).
- **Date Range**: `startDate` to `endDate` (inclusive UTC date-only midnight).
- **Status**: `DRAFT` | `OPEN` | `CLOSING` | `CLOSED` | `REOPENED` | `LOCKED`.
- **Audit**: `openedAt`, `openedBy`, `closedAt`, `closedBy`, `reopenedAt`, `reopenedBy`, `reopenReason`, `lockedAt`, `lockedBy`.

---

## C. PERIOD STATE MACHINE & TRANSITIONS

### State Definitions
| State | Posting Allowed? | Reversal Allowed? | Adjustments Allowed? | Description |
| :--- | :--- | :--- | :--- | :--- |
| **DRAFT** | NO | NO | NO | Period generated during FY creation, not yet initialized. |
| **OPEN** | YES | YES | YES | Standard active accounting period accepting journal postings. |
| **CLOSING** | NO | NO | NO | Temporary transient state while period preflight and FX revaluation run. |
| **CLOSED** | NO | NO | NO | Period closed after period-end procedure. Postings blocked. |
| **REOPENED** | YES | YES | YES | Temporarily reopened period for authorized adjustments (requires audit reason). |
| **LOCKED** | NO | NO | NO | Permanently locked period (e.g. post year-end close or audit freeze). Reopening prohibited. |

### Legal State Transitions
```text
[DRAFT]  ──(Initialize FY)──>  [CLOSED]
[CLOSED] ──(Open Period)────>  [OPEN]
[OPEN]   ──(Start Close)────>  [CLOSING]
[CLOSING]──(Close Success)──>  [CLOSED]
[CLOSING]──(Close Failed)───>  [OPEN]
[CLOSED] ──(Reopen)─────────>  [REOPENED] (requires audit reason)
[REOPENED]──(Reclose)───────>  [CLOSED]
[CLOSED] ──(Year-End Close)─>  [LOCKED]
```

### Invariants:
1. `DRAFT` periods cannot accept postings.
2. `CLOSING` state prevents concurrent double-closing or posting during revaluation runs.
3. Transition `CLOSED` → `REOPENED` requires explicit `reopenPeriod` permission and non-empty `reopenReason`.
4. Transition `CLOSED` → `LOCKED` occurs automatically upon Year-End Closing and is irreversible.
5. No transition out of `LOCKED` is permitted without administrative database override.

---

## D. POSTING CONTRACT & VALIDATION BOUNDARY

The Financial Core enforces a single posting gate for all business modules.

### Architectural Boundary:
```text
Commercial Module (Sales / Purchases / Inventory / Cash / Bank / Tax)
       ↓
Creates Transaction Request (documentDate, postingDate)
       ↓
Period Validation Gate (FinancialPeriodValidator.assertPostingAllowed)
       ├── 1. Validate active company context
       ├── 2. Resolve matching period (companyId, postingDate)
       ├── 3. Verify period.status in {OPEN, REOPENED}
       └── 4. Fail-closed if check fails
       ↓
Posting Engine (Account Resolution, Int64 Boundary, Double-Entry Balance)
       ↓
Posted Journal Entry Saved & Immutable
```

### Invariant:
> **No module may construct, save, or execute a journal entry without passing through `FinancialPeriodValidator.assertPostingAllowed(companyId, postingDate)`.**

---

## E. DATE SEMANTICS

| Field | Description | Used By | Mutable? | Period Ownership |
| :--- | :--- | :--- | :--- | :--- |
| **Document Date** | Date of original commercial document (e.g., vendor invoice date). | Commercial UI, Tax reporting, Vendor tracking. | Yes (in Draft) | NO |
| **Posting Date** | Authoritative accounting date for ledger entry. | Ledger, Trial Balance, P&L, Balance Sheet, Period Gate. | No (once Posted) | **YES (Sole Basis)** |
| **Created At** | System wall-clock timestamp of DB insertion. | Audit Trail, Concurrency, Replication. | No | NO |
| **Updated At** | System wall-clock timestamp of last modification. | Audit Trail, Replication. | Auto-updated | NO |

### Concrete Case Resolution:
* **Scenario**: Vendor Invoice dated `2026-01-31` arrives on `2026-02-03`. Period `2026-01` is `CLOSED`.
* **Resolution**:
  - `Document Date` = `2026-01-31` (preserved on purchase invoice record).
  - User sets `Posting Date` = `2026-02-01` (open period).
  - Accounting entry is assigned to `2026-02` period.
  - Trial balance and general ledger recognize the entry in February 2026.
  - Operation succeeds cleanly without reopening January.

---

## F. CLOSE / REOPEN CONTRACT

### Period Closing Preflight Check:
Before transitioning a period to `CLOSING` / `CLOSED`, the system MUST evaluate:
1. **Unposted Draft Journals**: Count draft entries with `postingDate` in period range. If count > 0, return blocker `UNPOSTED_JOURNALS_EXIST`.
2. **Missing Exchange Rates**: If `fxRevaluationEnabled = true`, list distinct foreign currency codes on journal lines in period date range. Verify exchange rate exists for `endDate`. If missing, return blocker `MISSING_EXCHANGE_RATES`.
3. **Period State**: Verify period status is `OPEN` or `REOPENED`.

### Period Closing Execution (Atomic & Idempotent):
1. Set `period.status = CLOSING`.
2. If `fxRevaluationEnabled = true`:
   - Compute asset/liability net foreign currency balances as of `endDate`.
   - Post FX revaluation journal entry (`voucherType = 'period_fx'`, `postingDate = endDate`).
3. Set `period.status = CLOSED`, `closedAt = now`, `closedBy = currentUser`.
4. Insert immutable `financial_period_closing_records` row (`status = 'completed'`).
5. Re-executing close on an already closed period returns the existing `PeriodClosingRecord` (`idempotentReplay = true`).

### Period Reopening Contract:
1. Verify user has permission `accounting.periods.reopen`.
2. Verify period status is `CLOSED` (cannot reopen `LOCKED` periods).
3. Require non-empty `reopenReason`.
4. Update `period.status = REOPENED`, `reopenedAt = now`, `reopenedBy = currentUser`, `reopenReason = reason`.
5. Log audit event. Existing posted entries remain untouched.

---

## G. YEAR-END CLOSE CONTRACT

1. **Prerequisites**:
   - All 12 (or N) periods of the Fiscal Year MUST be in `CLOSED` state.
   - Zero unposted drafts exist across the entire fiscal year.
2. **Closing Journal Entry**:
   - Calculates net Income / Expense account balances as of fiscal year `endDate`.
   - Generates and posts a Year-End Closing Journal Entry (`voucherType = 'year_end_close'`):
     - Clears all Revenue and Expense accounts to zero balance.
     - Offsets net profit/loss to `Retained Earnings` (Equity account).
3. **Opening Balance Generation**:
   - Carries forward Asset, Liability, and Equity balances into Period 1 of the new Fiscal Year as `OPENING_BALANCE` journal entry.
4. **Fiscal Year Lock**:
   - Sets `FiscalYear.status = CLOSED`.
   - Sets all child `FinancialFiscalPeriod.status = LOCKED`.

---

## H. DATABASE CONTRACT (PACKAGE `packages/financial`)

The GATE-08 database schema for the Financial Core package (`packages/financial`) extends the canonical Phase 2A-H / GATE-07 SQLite schema.

### Table 1: `financial_fiscal_years`
```sql
CREATE TABLE IF NOT EXISTS financial_fiscal_years (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    code TEXT NOT NULL CHECK(length(code) >= 1 AND length(code) <= 32),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 128),
    start_date INTEGER NOT NULL, -- UTC day epoch ms
    end_date INTEGER NOT NULL,   -- UTC day epoch ms
    status TEXT NOT NULL CHECK(status IN ('draft', 'open', 'closed', 'locked')),
    base_currency_code TEXT NOT NULL CHECK(length(base_currency_code) >= 3 AND length(base_currency_code) <= 8),
    period_count INTEGER NOT NULL CHECK(period_count > 0),
    period_frequency TEXT NOT NULL DEFAULT 'monthly',
    fx_revaluation_enabled INTEGER NOT NULL DEFAULT 0 CHECK(fx_revaluation_enabled IN (0, 1)),
    fx_gain_account_id TEXT CHECK(fx_gain_account_id IS NULL OR length(fx_gain_account_id) = 36),
    fx_loss_account_id TEXT CHECK(fx_loss_account_id IS NULL OR length(fx_loss_account_id) = 36),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    closed_at INTEGER,
    created_by TEXT,
    closed_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fy_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_fy_gain_acc FOREIGN KEY (company_id, fx_gain_account_id) REFERENCES financial_accounts(company_id, id),
    CONSTRAINT fk_fy_loss_acc FOREIGN KEY (company_id, fx_loss_account_id) REFERENCES financial_accounts(company_id, id),
    CONSTRAINT chk_fy_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fy_comp_id ON financial_fiscal_years(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fy_comp_code ON financial_fiscal_years(company_id, code);
CREATE INDEX IF NOT EXISTS idx_financial_fy_comp_dates ON financial_fiscal_years(company_id, start_date, end_date);
```

### Table 2: `financial_fiscal_periods`
```sql
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
    opened_by TEXT,
    closed_at INTEGER,
    closed_by TEXT,
    reopened_at INTEGER,
    reopened_by TEXT,
    reopen_reason TEXT,
    locked_at INTEGER,
    locked_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fp_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_fp_fy FOREIGN KEY (company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id) ON DELETE CASCADE,
    CONSTRAINT chk_fp_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fp_comp_id ON financial_fiscal_periods(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fp_comp_fy_num ON financial_fiscal_periods(company_id, fiscal_year_id, period_number);
CREATE INDEX IF NOT EXISTS idx_financial_fp_comp_dates ON financial_fiscal_periods(company_id, start_date, end_date);
```

### Table 3: `financial_period_closing_records`
```sql
CREATE TABLE IF NOT EXISTS financial_period_closing_records (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    fiscal_year_id TEXT NOT NULL CHECK(length(fiscal_year_id) = 36),
    period_id TEXT NOT NULL CHECK(length(period_id) = 36),
    closing_date INTEGER NOT NULL, -- UTC day epoch ms
    status TEXT NOT NULL CHECK(status IN ('completed', 'failed')),
    fx_revaluation_enabled INTEGER NOT NULL DEFAULT 0,
    fx_revaluation_executed INTEGER NOT NULL DEFAULT 0,
    fx_skip_reason TEXT,
    fx_gain REAL NOT NULL DEFAULT 0.0,
    fx_loss REAL NOT NULL DEFAULT 0.0,
    net_fx_difference REAL NOT NULL DEFAULT 0.0,
    journal_entry_id TEXT CHECK(journal_entry_id IS NULL OR length(journal_entry_id) = 36),
    created_by TEXT,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id),
    CONSTRAINT fk_pcr_journal FOREIGN KEY (company_id, journal_entry_id) REFERENCES financial_journal_entries(company_id, id)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_pcr_comp_id ON financial_period_closing_records(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_pcr_comp_period ON financial_period_closing_records(company_id, period_id);
```

---

## I. TENANCY CONTRACT & COMPOSITE ISOLATION

### Hardening Tenancy Invariants:
1. `company_id` column MUST be `NOT NULL` on `financial_fiscal_years`, `financial_fiscal_periods`, and `financial_period_closing_records`.
2. Every database query in repositories MUST enforce `WHERE company_id = activeCompanyId`.
3. Database foreign keys enforce composite tenant safety:
   - `fk_fp_fy`: `(company_id, fiscal_year_id) REFERENCES financial_fiscal_years(company_id, id)`
   - `fk_pcr_period`: `(company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id)`
4. Period resolution algorithm MUST reject any request where `requestCompanyId != activeCompanyId` or where target period belongs to another tenant.

---

## J. ERROR TAXONOMY

| Error Code | Description | Trigger Condition |
| :--- | :--- | :--- |
| `FISCAL_PERIOD_NOT_FOUND` | No period defined for date. | `postingDate` does not fall within any defined period. |
| `FISCAL_PERIOD_CLOSED` | Period is closed. | Attempting to post, edit, or reverse in a `CLOSED` period. |
| `FISCAL_PERIOD_LOCKED` | Period is permanently locked. | Attempting to post or reopen a `LOCKED` period. |
| `FISCAL_PERIOD_ALREADY_OPEN` | Period already open. | Calling `openPeriod` on an `OPEN` period. |
| `FISCAL_PERIOD_ALREADY_CLOSED`| Period already closed. | Calling `closePeriod` on a `CLOSED` period without changes. |
| `FISCAL_PERIOD_INVALID_RANGE` | Period date range invalid. | `startDate > endDate` or zero duration. |
| `FISCAL_PERIOD_OVERLAP` | Overlapping period/year. | Creating FY or period that overlaps existing date range. |
| `FISCAL_PERIOD_CROSS_TENANT` | Tenant mismatch attempt. | Accessing or posting using another company's period ID. |
| `FISCAL_PERIOD_DATE_OUTSIDE_YEAR`| Date outside FY range. | Period start/end dates extend beyond FY parent dates. |
| `FISCAL_YEAR_CLOSED` | Fiscal year closed. | Creating periods or posting in a closed fiscal year. |
| `POSTING_DATE_INVALID` | Invalid posting date. | Missing, null, or out-of-bounds posting timestamp. |

---

## K. ADVERSARIAL TENANCY & SECURITY TEST MATRIX

| Test ID | Scenario | Expected Behavior |
| :--- | :--- | :--- |
| **ATTACK-FP-01** | Company A requests Company B period details by `periodId`. | REJECT (`FISCAL_PERIOD_CROSS_TENANT` / `NOT_FOUND`). |
| **ATTACK-FP-02** | Company A posts journal using Company B `postingDate` and period ID. | REJECT at Period Gate (`FISCAL_PERIOD_CROSS_TENANT`). |
| **ATTACK-FP-03** | Valid `postingDate` passed with foreign `periodId` override. | Overrides IGNORED; period resolved strictly by `(companyId, postingDate)`. |
| **ATTACK-FP-04** | Same period code/number used across different companies. | ALLOWED (isolated by `company_id`). |
| **ATTACK-FP-05** | Attempt to create overlapping period within same company. | REJECT (`FISCAL_PERIOD_OVERLAP`). |
| **ATTACK-FP-06** | Duplicate FY code within same company. | REJECT (`UNIQUE(company_id, code)`). |
| **ATTACK-FP-07** | Post journal with `postingDate` in `CLOSED` period. | REJECT (`FISCAL_PERIOD_CLOSED`). |
| **ATTACK-FP-08** | Post journal with `postingDate` in `LOCKED` period. | REJECT (`FISCAL_PERIOD_LOCKED`). |
| **ATTACK-FP-09** | Post journal with `postingDate` outside any defined FY. | REJECT (`FISCAL_PERIOD_NOT_FOUND`). |
| **ATTACK-FP-10** | Backdated document posted into a closed historical period. | REJECT (`FISCAL_PERIOD_CLOSED`). |
| **ATTACK-FP-11** | Future posting into undefined future date range. | REJECT (`FISCAL_PERIOD_NOT_FOUND`). |
| **ATTACK-FP-12** | Reopen a `LOCKED` period without admin credentials. | REJECT (`FISCAL_PERIOD_LOCKED`). |
| **ATTACK-FP-13** | Cross-tenant reopen request (Company A reopens Company B period). | REJECT (`FISCAL_PERIOD_CROSS_TENANT`). |
| **ATTACK-FP-14** | Cross-tenant period close request. | REJECT (`FISCAL_PERIOD_CROSS_TENANT`). |

---

## L. MIGRATION CONTRACT

For historical transactions existing prior to GATE-08 explicit period persistence:
1. Historical posted journals contain `company_id` and `posting_date`.
2. Deterministic Resolution: Historical periods are auto-resolved by querying `(company_id, posting_date)`.
3. System Migration Script:
   - Identifies minimum and maximum historical `posting_date` per company.
   - Generates matching historical `financial_fiscal_years` and `financial_fiscal_periods`.
   - Marks historical periods matching fully closed years as `CLOSED` / `LOCKED`.
4. Fail-Safe: No historical journal entry is left unmapped or orphaned.

---

## M. LEGACY LOGIC REMOVAL PLAN

During GATE-08 implementation (subsequent phase), the following legacy mechanisms MUST be removed:
1. **Legacy Setting `closedThrough`**: Deprecate `accounting_fiscal_closed_through` in settings.
2. **Legacy `FiscalPeriodPolicy`**: Replace with domain service `FinancialPeriodValidator`.
3. **Ad-hoc Date Checks in Commercial Modules**: Remove inline date checks in Sales, Purchases, Inventory, and R&P adapters; route 100% of date validation through `FinancialPeriodValidator.assertPostingAllowed(companyId, postingDate)`.
4. **Null `companyId` Leaks**: Fix `FiscalYearRepositoryImpl` where `AccountingPeriods` rows were created with null `companyId`.

---

## ACCEPTANCE VERDICT

```text
DESIGN FROZEN / APPROVED FOR IMPLEMENTATION
```
*(Pending external review and formal approval before code execution)*
