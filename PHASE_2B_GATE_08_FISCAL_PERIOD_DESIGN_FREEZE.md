# NEXABIZ ERP — PHASE 2B — GATE-08
# FISCAL PERIOD DOMAIN — NEW ARCHITECTURE DESIGN & DESIGN FREEZE

> **DOCUMENT STATUS: FROZEN DESIGN SPECIFICATION**  
> **IMPLEMENTATION STATUS: NOT STARTED (STRICTLY PROHIBITED IN GATE-08 DESIGN PHASE)**  
> **GATE-01..07 STATUS: CLOSED AND LOCKED (FROZEN CONTRACTS)**

---

## 1. EXECUTIVE DECISION

NexaBiz ERP requires a brand-new, clean, company-scoped Fiscal Period domain architecture designed from ground-up business requirements rather than legacy code copying.

```text
STATUS VERDICT: GATE-08 DESIGN FROZEN
IMPLEMENTATION STATUS: IMPLEMENTATION NOT STARTED
```

### Key Architectural Mandates:
1. **Single Canonical Authority**: Fiscal Period is exclusively a **Posting Authorization and Control Boundary**. It does not own currency configurations, account master data, or financial balance stores.
2. **Posting Gate Primacy**: All ledger-writing operations (Journals, Sales, Purchases, Inventory, Cash/Bank, Tax, Costing, FX Revaluation) MUST pass through `FinancialPeriodGate.assertPostingAllowed(companyId, postingDate)` prior to transaction execution.
3. **Decoupled Technical Identity**: Period, Year, and Account identities are strictly UUID v7 (36 characters). Human-facing numbers/codes are display attributes only.
4. **Int64 Monetary Compliance**: All financial balances or thresholds associated with closing entries or revaluations strictly adhere to `DecimalMoney` / scaled `BigInt` ($10^8$ scale). `double`, `float`, or `REAL` types are strictly forbidden for authoritative amounts.
5. **Deterministic Resolution**: `resolvePeriod(companyId, postingDate)` strictly maps `(companyId, postingDate)` to exactly one period. Callers cannot supply or inject an arbitrary `periodId` to bypass date rules.

---

## 2. LEGACY ANALYSIS CLASSIFICATION

Every item extracted from the legacy system is classified according to its architectural validity:

| Legacy Component / Behavior | Classification | Business Requirement Behind It | New Architectural Treatment |
| :--- | :--- | :--- | :--- |
| `accounting_fiscal_closed_through` | **LEGACY WORKAROUND** | Ability to lock past dates prior to full fiscal year setup. | **REMOVED**. Replaced by explicit company-scoped period records. |
| `AccountingPeriodsCompanion` (null `companyId`) | **LEGACY DEFECT** | Per-period date filtering. | **REDESIGNED**. `company_id` is mandatory (`NOT NULL`) on all period tables. |
| `findPeriodContaining` without `company_id` | **SECURITY RISK / TENANCY DEFECT** | Find matching period for a date. | **REDESIGNED**. `resolvePeriod` enforces composite key `(company_id, posting_date)`. |
| `AccountingPeriodStatus` (`closed`, `open`, `closing`, `reopened`) | **BUSINESS REQUIREMENT** | Track operational lifecycle of accounting periods. | **KEPT & REFINED**. Clean 6-state machine (`DRAFT`, `OPEN`, `CLOSING`, `CLOSED`, `REOPENED`, `LOCKED`). |
| In-memory `FiscalPeriodPolicy` | **DUPLICATE AUTHORITY** | Gate journal posting dates. | **REMOVED**. Replaced by central `FinancialPeriodGate`. |
| Inline date checks in Sales/Purchases/R&P | **LEGACY WORKAROUND** | Validate posting dates before submission. | **REMOVED**. Commercial adapters call canonical `FinancialPeriodGate`. |
| `PeriodClosingService` FX revaluation | **DUPLICATE AUTHORITY** | Execute currency revaluation at period close. | **REDESIGNED**. Revaluation policy owned by FX domain; journal posted via canonical `PostingEngine`. |

---

## 3. BUSINESS REQUIREMENTS

1. **Fiscal Year**: The top-level calendar header for a company's financial accounting cycle, usually covering 12 consecutive months. Owned strictly by a single company (`companyId`).
2. **Fiscal Period**: The sub-interval (typically 1 month) within a Fiscal Year representing an active posting window.
3. **Open Period**: State where financial transactions can be posted into the general ledger.
4. **Closed Period**: State where period-end validation and reporting are complete. New postings, edits, and reversals are blocked.
5. **Reopened Period**: State where a previously closed period is temporarily made available for audited adjustments under strict permission control.
6. **Locked Period**: Permanent immutable state achieved after year-end close or audit freeze. Cannot be reopened.
7. **Date Semantics**:
   - **Document Date**: Commercial date of the document (vendor invoice date, receipt date). Mutable during draft state. Irrelevant to accounting period validation after posting.
   - **Posting Date**: Authoritative accounting-effective date. Determines period belonging, FX exchange rate snapshot, and ledger placement. Immutable once posted.
   - **System Timestamp (`createdAt` / `updatedAt`)**: Wall-clock audit timestamp.
8. **Posting Gate**: Central gate that evaluates `(companyId, postingDate)` against period state before any journal entry is saved or posted.
9. **Closing Requirements**:
   - Preflight check for unposted drafts and missing exchange rates.
   - Idempotent execution (running close twice returns the existing closing record).
   - Generates standard canonical FX revaluation journal if enabled.
10. **Reopening Requirements**: Requires permission `accounting.periods.reopen` + mandatory non-empty audit `reopenReason`. Reopening never alters historical posted entries.
11. **Year-End Closing Requirements**: All 12 periods must be `CLOSED`. Automatically posts a Retained Earnings closing journal clearing revenue/expense accounts to zero and locks the fiscal year.
12. **Opening Balances**: Carries forward balance sheet account balances as standard `OPENING_BALANCE` journal entries into Period 1 of the new fiscal year.

---

## 4. EVIDENCE MATRIX

| # | Evidence Item | Source Location | Actual Behavior | Authority Type | Scope | New Design Decision |
| - | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | `fiscal_years` table | `fiscal_years_table.dart` | Stores FY header metadata. | Persistence | Tenant | **KEEP & MIGRATE** to `packages/financial`. |
| 2 | `accounting_periods` table | `accounting_periods_table.dart` | Stores period date ranges and status. | Persistence | Tenant | **REDESIGN** with strict `company_id NOT NULL`. |
| 3 | `period_closing_records` table | `period_closing_records_table.dart` | Stores closing logs & FX result summary. | Persistence | Tenant | **KEEP & RESTRUCTURE** composite foreign keys. |
| 4 | `PeriodValidatorPort` | `period_validator_port.dart` | Abstract gate interface (`assertEntryAllowed`). | Domain Port | Global | **KEEP & EXPAND** as `FinancialPeriodGatePort`. |
| 5 | `AccountingPeriodValidator` | `accounting_period_validator.dart` | Validates date against DB periods + legacy fallback. | Domain Service | Tenant | **REDESIGN** without legacy fallback. |
| 6 | `FiscalYearRepositoryImpl` | `fiscal_year_repository_impl.dart` | DB repository for FY and periods. | Infrastructure | Tenant | **REDESIGN** to enforce tenant scope on all queries. |
| 7 | `JournalPostingService` | `journal_posting_service.dart` | Posts journals after checking period validator. | App Service | Tenant | **KEEP** as consumer of canonical Posting Gate. |

---

## 5. CONTRADICTION MATRIX

| Contradiction Found | Legacy Artifact A | Legacy Artifact B | Resolution Decision |
| :--- | :--- | :--- | :--- |
| **Period Ownership vs Null Company ID** | `AccountingPeriodsTable` has `companyId` column. | `FiscalYearRepositoryImpl.createFiscalYear` inserts periods with `companyId = null`. | **RESOLUTION**: `company_id` is mandatory (`NOT NULL`) on all period tables. |
| **Caller Period Injection vs Date Resolution** | `JournalEntry` contains `postingDate`. | Some UI services passed explicit `periodId`. | **RESOLUTION**: `periodId` is strictly resolved by `FinancialPeriodResolver` using `(companyId, postingDate)`. Caller cannot inject `periodId`. |
| **Closed Period Reversal vs Date Override** | Reversal requests used original posting date. | Original period was `CLOSED`. | **RESOLUTION**: Reversals for entries in closed periods MUST be posted into an `OPEN` period with a new `postingDate`. |
| **Base Currency Authority** | `FiscalYearsTable` stored `baseCurrencyCode`. | `CompanyContext` owns functional currency. | **RESOLUTION**: Fiscal Period domain queries Company Currency Authority (GATE-01/02) and does not maintain duplicate currency state. |

---

## 6. FROZEN DEPENDENCIES (GATE-01..07)

```text
GATE-01: Int64 Monetary Precision & Scaled BigInt (10^8)  --> FROZEN CONTRACT
GATE-02: Company Functional Currency & Exchange Rates    --> FROZEN CONTRACT
GATE-03: Double-Entry Balance & Journal Invariants       --> FROZEN CONTRACT
GATE-04: Canonical PostingEngine Authority              --> FROZEN CONTRACT
GATE-05: Account Resolution & SubjectAccountBinding     --> FROZEN CONTRACT
GATE-06: ContextAccount Resolution & Tenant Scope       --> FROZEN CONTRACT
GATE-07: FinancialAccount.id Technical Identity & COA   --> FROZEN CONTRACT
```

---

## 7. DOMAIN MODEL & OWNERSHIP BOUNDARIES

### Domain Entities:

```text
FinancialFiscalYear (Entity)
  ├── id: UUID v7 (36 chars)
  ├── companyId: UUID v7 (36 chars)
  ├── code: String (1..32)
  ├── name: String (1..128)
  ├── startDate: DateTime (UTC Day Midnight)
  ├── endDate: DateTime (UTC Day Midnight)
  ├── status: FiscalYearStatus (DRAFT, OPEN, CLOSED, LOCKED)
  ├── periodCount: Int (1..N)
  └── fxRevaluationEnabled: Bool

FinancialFiscalPeriod (Entity)
  ├── id: UUID v7 (36 chars)
  ├── companyId: UUID v7 (36 chars)
  ├── fiscalYearId: UUID v7 (36 chars)
  ├── periodNumber: Int (1..N)
  ├── name: String (1..64)
  ├── startDate: DateTime (UTC Day Midnight)
  ├── endDate: DateTime (UTC Day Midnight)
  └── status: PeriodState (DRAFT, OPEN, CLOSING, CLOSED, REOPENED, LOCKED)
```

### Authority Map:
- **Currency Authority**: Functional Currency Domain.
- **Account Authority**: FinancialAccount Domain (GATE-07).
- **Posting Authority**: Canonical `PostingEngine` (GATE-04).
- **Period Authorization Authority**: NEW `FinancialPeriodGate` (GATE-08).

---

## 8. FISCAL YEAR OWNERSHIP

- **DECISION**: Fiscal Year is owned by `companyId`.
- **WHY**: Ensures multi-tenant isolation and per-company fiscal calendar customization.
- **EVIDENCE**: Multi-company tenancy requirement (Rule 50-tenancy.md).
- **ALTERNATIVES**: Global system-wide fiscal calendar.
- **REJECTED**: Violates tenant isolation; companies operate under different tax jurisdictions.
- **IMPACT**: Fiscal Year queries strictly filter by `company_id = activeCompanyId`.

---

## 9. FISCAL PERIOD OWNERSHIP

- **DECISION**: Fiscal Period is an authorization boundary, NOT a financial balance store.
- **WHY**: Prevents duplicate financial truth and ledger balance divergence.
- **EVIDENCE**: General ledger balances are derived strictly from `JournalLines`.
- **ALTERNATIVES**: Storing summary balances directly inside `financial_fiscal_periods`.
- **REJECTED**: Creates secondary financial truth susceptible to synchronization drift.
- **IMPACT**: Financial reporting queries sum `JournalLines` directly within period date bounds.

---

## 10. DATE SEMANTICS CONTRACT

- **DECISION**: `JournalEntry.postingDate` is the SOLE basis for period resolution and period state validation.
- **WHY**: Document dates vary by external vendors and billing cycles; accounting ledgers must reflect the financial posting date.
- **EVIDENCE**: Statutory accounting standards (IFRS / GAAP) require ledger recognition by posting date.
- **ALTERNATIVES**: Validating `documentDate` against period state.
- **REJECTED**: Blocks entry of legitimate historical vendor invoices into current open periods.
- **IMPACT**: Commercial documents with old `documentDate` can post cleanly if their `postingDate` is in an `OPEN` period.

---

## 11. PERIOD RESOLUTION CONTRACT

```dart
abstract class FinancialPeriodResolver {
  Future<FinancialFiscalPeriod> resolvePeriod({
    required String companyId,
    required DateTime postingDate,
  });
}
```

- **Invariants**:
  1. `postingDate` is converted to UTC Day Midnight epoch milliseconds.
  2. Queries `financial_fiscal_periods` WHERE `company_id = companyId` AND `start_date <= postingDateMs` AND `end_date >= postingDateMs`.
  3. Returns exactly one `FinancialFiscalPeriod`.
  4. Throws `FISCAL_PERIOD_NOT_FOUND` if no period exists for the date.

---

## 12. POSTING GATE & TRANSACTION PIPELINE

```text
Commercial Module Transaction Request
       │
       ▼ (1. Obtain active company context)
activeCompanyId
       │
       ▼ (2. Resolve Period from postingDate)
FinancialPeriodResolver.resolvePeriod(activeCompanyId, postingDate)
       │
       ▼ (3. Assert Period Eligibility)
FinancialPeriodGate.assertPostingAllowed(period)
       ├── Status in {OPEN, REOPENED} ? YES ──► Continue
       └── Status in {DRAFT, CLOSING, CLOSED, LOCKED} ──► THROW FISCAL_PERIOD_CLOSED / LOCKED
       │
       ▼ (4. Invoke Canonical PostingEngine inside DB Transaction)
PostingEngine.post(journalEntry)
       │
       ▼ (5. Commit Posted Journal Entry)
DB Transaction Committed
```

---

## 13. CONCURRENCY & RACE-CONDITION MODEL

- **DECISION**: Period state checks and journal posting execute within an immediate SQLite `EXCLUSIVE` transaction boundary or double-checked atomic lock.
- **WHY**: Prevents Transaction A from posting into Period P while Transaction B concurrently closes Period P.
- **EVIDENCE**: SQLite concurrency mechanics under Drift database transactions.
- **ALTERNATIVES**: In-memory mutex or optimistic locking without DB transaction.
- **REJECTED**: In-memory locks fail across multiple app isolates or process instances.
- **IMPACT**: `PostingEngine` and `PeriodGate` execute inside a shared atomic SQLite transaction block.

---

## 14. STATE MACHINE SPECIFICATION

```text
  [DRAFT]  ──►  [CLOSED]  ◄──►  [OPEN]  ──►  [CLOSING]
                                  ▲              │
                                  │ (Reclose)    ▼
                              [REOPENED] ◄── [CLOSED]  ──►  [LOCKED]
```

| Current State | Target State | Trigger Operation | Required Permission | Audit Required? |
| :--- | :--- | :--- | :--- | :--- |
| **DRAFT** | **CLOSED** | Initial FY Setup | `accounting.periods.create` | Yes |
| **CLOSED** | **OPEN** | Open Period | `accounting.periods.open` | Yes |
| **OPEN** | **CLOSING** | Start Close Preflight | `accounting.periods.close` | Yes |
| **CLOSING** | **CLOSED** | Close Success | `system.closing_service` | Yes (Closing Record) |
| **CLOSING** | **OPEN** | Preflight Failed | `system.closing_service` | Yes (Failure Reason) |
| **CLOSED** | **REOPENED** | Reopen Period | `accounting.periods.reopen` | Yes (Reason String) |
| **REOPENED**| **CLOSED** | Reclose Period | `accounting.periods.close` | Yes |
| **CLOSED** | **LOCKED** | Year-End Close | `accounting.yearend.close` | Yes (Year-End Journal) |

---

## 15. CLOSING STATE ANALYSIS

- **DECISION**: Retain `CLOSING` as a transient status during close execution.
- **WHY**: Signals an in-flight closing process to concurrent users and blocks new posting while FX revaluation calculations execute.
- **EVIDENCE**: Prevents race conditions during multi-step period close workflows.
- **ALTERNATIVES**: Single-step immediate state flip from `OPEN` to `CLOSED`.
- **REJECTED**: Risk of unposted journals sneaking in between FX calculation and status update.
- **IMPACT**: If a crash occurs while in `CLOSING`, recovery service resets status back to `OPEN` after verifying no partial closing records were committed.

---

## 16. CLOSE OPERATION CONTRACT

```dart
abstract class PeriodClosingUseCase {
  Future<PeriodClosingResult> closePeriod({
    required String companyId,
    required String periodId,
    required String userId,
  });
}
```

- **Steps**:
  1. Verify zero unposted draft journals exist in period date range.
  2. Verify exchange rates exist for foreign currency positions on `endDate`.
  3. Transition status `OPEN` → `CLOSING`.
  4. Post FX Revaluation entry (`voucherType = 'period_fx'`) if enabled.
  5. Transition status `CLOSING` → `CLOSED`.
  6. Insert `financial_period_closing_records` row.

---

## 17. FX REVALUATION INTEGRATION

- **DECISION**: FX Revaluation journal entries are posted using canonical `PostingEngine` with `voucherType = 'period_fx'` and `postingDate = period.endDate`.
- **WHY**: Ensures FX entries follow standard double-entry balancing and accounting rules.
- **EVIDENCE**: GATE-02/03 currency and posting engine invariants.
- **ALTERNATIVES**: Direct mutation of account balances.
- **REJECTED**: Violates journal balance immutability and ledger integrity.
- **IMPACT**: FX Revaluation results are 100% visible and auditable as standard journal entries.

---

## 18. REOPEN OPERATION CONTRACT

- **DECISION**: Reopening a period transits status from `CLOSED` to `REOPENED` and requires a mandatory `reopenReason`.
- **WHY**: Provides auditability for administrative adjustments in closed periods.
- **EVIDENCE**: Compliance with audit trail rules.
- **ALTERNATIVES**: Allowing silent posting into closed periods with admin permission.
- **REJECTED**: Destroys audit integrity; period state must explicitly reflect open status.
- **IMPACT**: Reopened periods allow posting until explicitly reclosed.

---

## 19. LOCK OPERATION CONTRACT

- **DECISION**: Locking a period (`LOCKED`) is permanent and irreversible by application layer code.
- **WHY**: Protects finalized fiscal years and audited historical periods from tampering.
- **EVIDENCE**: Statutory financial compliance regulations.
- **ALTERNATIVES**: Allowing admins to unlock locked periods via UI button.
- **REJECTED**: Creates security vulnerability and violates historical freeze guarantee.
- **IMPACT**: Transition to `LOCKED` occurs strictly via Year-End Close workflow.

---

## 20. YEAR-END CLOSE CONTRACT

- **DECISION**: Year-End Close generates a `year_end_close` journal clearing Income Statement accounts to `Retained Earnings` and transits all child periods to `LOCKED`.
- **WHY**: Formally closes the fiscal year and locks historical ledgers.
- **EVIDENCE**: Standard accounting year-end closing procedure.
- **ALTERNATIVES**: Leaving revenue/expense balances open indefinitely.
- **REJECTED**: Corrupts P&L reporting for subsequent fiscal years.
- **IMPACT**: Retained Earnings reflects net profit/loss; revenue and expense balances reset to zero for the new fiscal year.

---

## 21. OPENING BALANCE CONTRACT

- **DECISION**: Opening balances are posted as standard `OPENING_BALANCE` journals into Period 1 of the new Fiscal Year.
- **WHY**: Preserves double-entry balance and single financial truth in `JournalLines`.
- **EVIDENCE**: GATE-03 journal invariants.
- **ALTERNATIVES**: Maintaining separate opening balance fields on `financial_accounts`.
- **REJECTED**: Dual source of truth leading to ledger discrepancy.
- **IMPACT**: Trial balance queries seamlessly include opening balances as standard ledger lines.

---

## 22. DATABASE SCHEMA DESIGN (PACKAGE `packages/financial`)

```sql
-- Fiscal Years Header Table
CREATE TABLE IF NOT EXISTS financial_fiscal_years (
    id TEXT NOT NULL CHECK(length(id) = 36),
    company_id TEXT NOT NULL CHECK(length(company_id) = 36),
    code TEXT NOT NULL CHECK(length(code) >= 1 AND length(code) <= 32),
    name TEXT NOT NULL CHECK(length(name) >= 1 AND length(name) <= 128),
    start_date INTEGER NOT NULL, -- UTC day epoch ms
    end_date INTEGER NOT NULL,   -- UTC day epoch ms
    status TEXT NOT NULL CHECK(status IN ('draft', 'open', 'closed', 'locked')),
    period_count INTEGER NOT NULL CHECK(period_count > 0),
    period_frequency TEXT NOT NULL DEFAULT 'monthly',
    fx_revaluation_enabled INTEGER NOT NULL DEFAULT 0 CHECK(fx_revaluation_enabled IN (0, 1)),
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    closed_at INTEGER,
    created_by TEXT,
    closed_by TEXT,
    PRIMARY KEY (id),
    CONSTRAINT fk_fy_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT chk_fy_dates CHECK(start_date <= end_date)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fy_comp_id ON financial_fiscal_years(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_fy_comp_code ON financial_fiscal_years(company_id, code);
CREATE INDEX IF NOT EXISTS idx_financial_fy_comp_dates ON financial_fiscal_years(company_id, start_date, end_date);

-- Fiscal Periods Sub-Table
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

-- Period Closing Audit Log Table
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
    journal_entry_id TEXT CHECK(journal_entry_id IS NULL OR length(journal_entry_id) = 36),
    created_by TEXT,
    created_at INTEGER NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_pcr_company FOREIGN KEY (company_id) REFERENCES companies(id) ON DELETE RESTRICT,
    CONSTRAINT fk_pcr_period FOREIGN KEY (company_id, period_id) REFERENCES financial_fiscal_periods(company_id, id) ON DELETE RESTRICT
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_pcr_comp_id ON financial_period_closing_records(company_id, id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_pcr_comp_period ON financial_period_closing_records(company_id, period_id);
```

---

## 23. TENANCY CONTRACT

- All tables require `company_id TEXT NOT NULL CHECK(length(company_id) = 36)`.
- Foreign key `fk_fp_fy` enforces composite tenancy match `(company_id, fiscal_year_id)`.
- Repositories MUST append `WHERE company_id = activeCompanyId` to 100% of queries.
- Any attempt to access a period across company boundaries raises `FISCAL_PERIOD_CROSS_TENANT`.

---

## 24. DATE RANGE INTEGRITY CONTRACT

- **Overlap Prevention**: Creating a Fiscal Year or Period checks existing records for `company_id`:
  $$\neg \exists P : (P.\text{startDate} \le \text{newEndDate}) \land (P.\text{endDate} \ge \text{newStartDate})$$
- Violations raise `FISCAL_PERIOD_OVERLAP`.

---

## 25. DELETE / ARCHIVE CONTRACT

- **Hard Delete Prohibition**: If a `FinancialFiscalPeriod` has associated `JournalEntry` rows, `ON DELETE RESTRICT` is enforced at database level.
- **Archive Policy**: Closed fiscal years remain stored in SQLite for auditing and historical financial statements.

---

## 26. AUDIT MODEL

- Reopen operations record `reopenedAt`, `reopenedBy`, and `reopenReason` directly on `financial_fiscal_periods`.
- Closing operations write an immutable row to `financial_period_closing_records`.

---

## 27. IDEMPOTENCY CONTRACT

- Executing `closePeriod` on an already closed period returns the existing `financial_period_closing_records` row without regenerating FX revaluation journals.
- Executing `YearEndClose` twice returns the existing `year_end_close` journal entry.

---

## 28. MIGRATION CONTRACT

- **Historical Data Resolution**: Existing posted entries with `posting_date` map deterministically to auto-generated historical fiscal years and periods during migration.
- **Hard Stop Condition**: If an unresolvable journal date is encountered during migration, migration BLOCKS and raises `MIGRATION_RECONCILIATION_REQUIRED`.

---

## 29. LEGACY REMOVAL PLAN

| Legacy Component | Removal Action | New Authority |
| :--- | :--- | :--- |
| `closedThrough` setting | Remove `accounting_fiscal_closed_through` setting reader. | `FinancialPeriodGate` |
| Legacy `AccountingPeriodValidator` | Delete implementation. | `FinancialPeriodGate` |
| Legacy `FiscalPeriodPolicy` | Delete implementation. | `FinancialPeriodGate` |
| Null `companyId` period generation | Fix repository period creation. | Mandatory `company_id` |

---

## 30. MODULE INTEGRATION CONTRACT

All business modules (Sales, Purchases, Inventory, Receipts & Payments, Cash Registers) interact with accounting solely by submitting transaction drafts to the Financial Core posting pipeline. No module writes directly to financial tables or performs independent date validation.

---

## 31. ERROR TAXONOMY

1. `PERIOD_NOT_FOUND`
2. `PERIOD_OUTSIDE_FISCAL_YEAR`
3. `PERIOD_CLOSED`
4. `PERIOD_LOCKED`
5. `FISCAL_YEAR_CLOSED`
6. `CROSS_TENANT_PERIOD`
7. `INVALID_PERIOD_RANGE`
8. `PERIOD_OVERLAP`
9. `POSTING_DATE_INVALID`

---

## 32. INVARIANT MATRIX

| ID | Invariant | Enforcement Layer | Test Strategy |
| :--- | :--- | :--- | :--- |
| **FP-INV-01** | Period owned by single tenant (`company_id`). | Database FK + Repository | Adversarial cross-tenant query |
| **FP-INV-02** | Period resolved strictly by `postingDate`. | Domain Resolver | Date resolution unit tests |
| **FP-INV-03** | Closed period rejects new journal posting. | Posting Gate | Attempt post in closed period |
| **FP-INV-04** | Locked period rejects reopening without admin override. | State Machine | Attempt reopen locked period |
| **FP-INV-05** | Posted journal entry is 100% immutable. | PostingEngine | Attempt update posted journal |
| **FP-INV-06** | Double-entry balance maintained for all period journals. | PostingEngine | Assert debit == credit |

---

## 33. ADVERSARIAL ATTACK MATRIX

| Attack ID | Scenario | Expected Outcome |
| :--- | :--- | :--- |
| **ATTACK-FP-01** | Company A queries Company B period by ID. | REJECT (`CROSS_TENANT_PERIOD`). |
| **ATTACK-FP-02** | Company A posts journal using Company B date/period. | REJECT at Posting Gate. |
| **ATTACK-FP-03** | Caller passes arbitrary `periodId` parameter to override date. | Parameter IGNORED; resolved by `postingDate`. |
| **ATTACK-FP-04** | Attempt to create overlapping period in same company. | REJECT (`PERIOD_OVERLAP`). |
| **ATTACK-FP-05** | Post journal with `postingDate` in `CLOSED` period. | REJECT (`PERIOD_CLOSED`). |
| **ATTACK-FP-06** | Post journal with `postingDate` in `LOCKED` period. | REJECT (`PERIOD_LOCKED`). |
| **ATTACK-FP-07** | Reopen `LOCKED` period without authorization. | REJECT (`PERIOD_LOCKED`). |
| **ATTACK-FP-08** | Concurrent close and journal post on same period. | Atomic SQLite transaction prevents race condition. |
| **ATTACK-FP-09** | Re-running close command on closed period. | Idempotent replay; returns existing record. |
| **ATTACK-FP-10** | Post journal with date outside any fiscal year. | REJECT (`PERIOD_NOT_FOUND`). |

---

## 34. TEST PLAN

- **Unit Tests**: Test `FinancialPeriodResolver`, `FinancialPeriodGate`, and state machine transitions.
- **Integration Tests**: Test period close preflight, FX revaluation generation, and atomic DB transactions.
- **Adversarial Security Tests**: Execute all 10 attack scenarios in isolated multi-tenant environment.

---

## 35. OPEN DECISIONS

**NONE.** All business rules, date semantics, state transitions, and database constraints are frozen.

---

## 36. REJECTED ALTERNATIVES

- **Rejected**: In-memory `closedThrough` fallback date.
  - *Why*: Violates tenant isolation and fails to support multi-company operations.
- **Rejected**: Allowing caller-supplied `periodId` overrides during journal posting.
  - *Why*: Risk of inconsistent accounting dates and period manipulation.
- **Rejected**: Storing financial balances inside period tables.
  - *Why*: Creates duplicate financial truth susceptible to synchronization drift.

---

## 37. FINAL DESIGN FREEZE DECISION

```text
GATE-08 DESIGN FROZEN
IMPLEMENTATION NOT STARTED
```
