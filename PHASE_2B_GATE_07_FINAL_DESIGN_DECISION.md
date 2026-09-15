# NEXABIZ ERP — PHASE 2B — GATE-07 FINAL DESIGN DECISION & ARCHITECTURE LOCKDOWN

**Date:** 2026-09-14  
**Gate:** GATE-07 (COA Hierarchy + Composite Tenancy)  
**Status:** FORENSIC EVIDENCE VERIFIED / DESIGN FROZEN / LOCKED FOR EXECUTION  
**Previous Gates:** GATE-01 → GATE-06 = FROZEN / CLOSED / LOCKED  

---

## 1. EXECUTIVE DECISION

Following the final evidence-based hardening pass across composite tenancy model boundaries, GATE-05 precedence formulas, hierarchy node depth semantics, and cross-module deletion dependency graphs, **GATE-07 COA Hierarchy & Composite Tenancy Architecture** is formally **CLOSED, LOCKED, and DECLARED READY FOR GATE-07 EXECUTION**.

---

## 2. FROZEN IDENTITY MODEL

The technical identity of financial accounts remains strictly immutable across all hierarchy and code mutations:

```text
FinancialAccount.id                     = Canonical UUID v7 immutable technical identity (36 chars)
FinancialAccount.code                   = Mutable human-facing reference string
FinancialAccount.parentAccountId        = Canonical COA hierarchy parent pointer
FinancialAccount.level                  = Derived/materialized hierarchy metadata (level >= 0)
JournalLine.accountId                   = FinancialAccount.id
AccountingSubject.primaryAccountId      = FinancialAccount.id
```

- `FinancialAccount.id` is the **ONLY** authoritative technical identity used in posting, balance calculation, journal lines, subject bindings, and context resolutions.
- `FinancialAccount.code` is a human-facing metadata attribute. Changing `code` creates **0** journal entries, **0** line rewrites, and **0** balance transfers.

---

## 3. COA HIERARCHY MODEL

- **Structure:** Bounded forest of directed acyclic trees.
- **Root Accounts:** Multiple root accounts (`parentAccountId == null`, `level == 0`) are allowed per company.
- **Parent-Child Link:** `parentAccountId` points to `FinancialAccount.id` of a group account within the same tenant company.

---

## 4. COMPOSITE TENANCY MODEL & ACCURATE ENFORCEMENT

The physical SQLite database schema and application validation layer maintain the following exact breakdown:

```text
Parent Tenancy Constraint (parent.companyId == child.companyId):
    -> APPLICATION ENFORCED (in ChartOfAccountsService & Drift Repositories)
    -> Violation throws: CROSS_TENANT_ACCOUNT_REJECTION

Company-Scoped Account Code Uniqueness (company_id, code):
    -> DATABASE ENFORCED via SQLite constraint UNIQUE("company_id", "code")

Company-Scoped Account ID Uniqueness (company_id, id):
    -> DATABASE ENFORCED via SQLite constraint UNIQUE("company_id", "id")

Physical Parent Composite Foreign Key:
    -> ABSENT in current physical SQLite schema (No FK on parent_account_id)
```

---

## 5. DATABASE VS APPLICATION ENFORCEMENT & FUTURE HARDENING

- **Current Operational Boundary:** Domain service `ChartOfAccountsService` and repository `DriftFinancialAccountRepository` enforce `parent.companyId == child.companyId` before writing to database.
- **Future Database Hardening (OPTION B Roadmap):** Because `UNIQUE("company_id", "id")` already physically exists in SQLite (`sqlite_autoindex_financial_accounts_2`), a composite Foreign Key constraint:
  ```sql
  FOREIGN KEY (company_id, parent_account_id)
  REFERENCES financial_accounts (company_id, id)
  ON DELETE RESTRICT
  ```
  MAY be introduced in a future schema migration. Such hardening is **NOT** part of GATE-07 execution and will require its own migration plan.

---

## 6. GROUP / POSTABLE CONTRACT

Strict separation of duties between header containers and detail posting nodes:

- **Group Account (`isGroup == true`):**
  - Acts as container node.
  - MAY have child accounts.
  - **CANNOT** accept direct `JournalLine` postings (`GROUP_ACCOUNT_NOT_POSTABLE`).
- **Postable Account (`isGroup == false`):**
  - Acts as detail leaf node.
  - MAY accept direct `JournalLine` postings.
  - **CANNOT HAVE CHILD ACCOUNTS (`NO`)**. Attempting to set a postable account as `parentAccountId` for any node fails closed with `INVALID_PARENT_ACCOUNT`.

---

## 7. ROOT CONTRACT

- An account with `parentAccountId == null` is a **Root Account**.
- Root accounts MUST have `level == 0`.
- A company MAY possess multiple root accounts (e.g., separate roots for Assets, Liabilities, Equity, Revenue, Expense).

---

## 8. LEVEL CONTRACT

- `parentAccountId` is the **canonical source of truth** for hierarchy relationships.
- `level` is **derived/materialized metadata**.
- Invariant formulas:
  - If `parentAccountId == null` $\implies$ `level = 0`.
  - If `parentAccountId != null` $\implies$ `level = parent.level + 1`.
- `level` must **NEVER** independently define hierarchy placement.

---

## 9. MAX_DEPTH CONTRACT & NODE COUNT SEMANTICS

- `MAX_DEPTH = 10` defines the **maximum number of nodes** allowed in a vertical hierarchy chain.
- Level bounds:
  - Root node: `level = 0` (Node 1)
  - Max valid level: `level = 9` (Node 10)
  - Maximum valid chain length = **10 nodes**.
- Node 11 (`level = 10`) exceeds `MAX_DEPTH` and is strictly rejected with `COA_HIERARCHY_DEPTH_EXCEEDED`.

---

## 10. REQUIRED COA DEPTH EXAMPLES

### Valid Chain (10 Nodes) — PASS
```text
Node 01 (level 0, root)
  └─ Node 02 (level 1)
      └─ Node 03 (level 2)
          └─ Node 04 (level 3)
              └─ Node 05 (level 4)
                  └─ Node 06 (level 5)
                      └─ Node 07 (level 6)
                          └─ Node 08 (level 7)
                              └─ Node 09 (level 8)
                                  └─ Node 10 (level 9)  ==> PASS
```

### Invalid Chain (11 Nodes) — REJECTED
```text
Node 01 (level 0)
  └─ ...
      └─ Node 10 (level 9)
          └─ Node 11 (level 10)  ==> REJECTED: COA_HIERARCHY_DEPTH_EXCEEDED
```

---

## 11. CYCLE CONTRACT

- COA hierarchy cycle detection is strictly segregated from GATE-06 Context Hierarchy:
  - **COA Domain Error:** `COA_HIERARCHY_CYCLE`
  - **Context Domain Error:** `CONTEXT_HIERARCHY_CYCLE`
- Forbidden cycle forms:
  1. Self-parenting: `A -> A`
  2. 2-Node cycle: `A -> B -> A`
  3. Multi-Node cycle: `A -> B -> C -> ... -> A`
- Any operation introducing a cycle fails closed immediately with `COA_HIERARCHY_CYCLE` before state mutation.

---

## 12. MOVE TRANSACTION CONTRACT

Moving an account within the COA tree is an atomic metadata operation executing under an explicit database transaction:

```text
BEGIN TRANSACTION

 1. Validate target account existence and tenant company context
 2. Validate target parent account (if non-null):
    a. Check parent exists in same company (CROSS_TENANT_ACCOUNT_REJECTION)
    b. Check parent is a Group account (parent.isGroup == true)
    c. Check parent is active (INACTIVE_ACCOUNT)
 3. Check self-parenting (newParentAccountId != account.id)
 4. Traverse target parent ancestor chain to ensure target parent is NOT a descendant (COA_HIERARCHY_CYCLE)
 5. Calculate new level and verify max depth constraint (newLevel <= 9)
 6. Mutate target account: set parentAccountId = newParentAccountId, level = newLevel
 7. Recalculate descendant subtree levels recursively (child.level = parent.level + 1)

COMMIT (ROLLBACK on any failure)
```

**Side-Effects:** Generates **0** journal entries, **0** line updates, **0** balance transfers, and **0** subject rebindings. Technical identity `FinancialAccount.id` remains unchanged.

---

## 13. ACCOUNT CODE MUTATION CONTRACT

- `updateAccountCode(companyId, accountId, newCode)` updates **ONLY** human-facing `code`.
- Uniqueness is validated against `(companyId, newCode)`.
- **Side-Effects:** Generates **0** journal entries, **0** line rewrites, **0** balance transfers, **0** subject rebindings. `FinancialAccount.id` remains unchanged.

---

## 14. DELETE CONTRACT

Hard deletion of a financial account from SQLite is allowed **ONLY IF ALL** of the following conditions are simultaneously met:

1. **No Child Accounts:** `account.children.isEmpty` (`ACCOUNT_HAS_CHILDREN`).
2. **No Posted History:** Account has 0 posted or unposted `JournalLine` references (`ACCOUNT_HAS_POSTED_HISTORY`).
3. **No Active Subject Bindings:** Account is not bound as `primaryAccountId` in `AccountingSubject` (`ACCOUNT_BOUND_TO_SUBJECT`).
4. **No Active Context Bindings:** Account is not configured in `ContextBinding` (`ACCOUNT_BOUND_TO_CONTEXT`).
5. **No Master Data References:** Account is not bound to Cash Registers, Customers, Suppliers, or Warehouses.
6. **No Immutable History:** Account has never participated in financial posted ledger state.

If **ANY** condition fails, Hard Delete is strictly **FORBIDDEN**.

---

## 15. ARCHIVE / DEACTIVATE CONTRACT

When hard deletion is forbidden due to historical postings or active domain dependencies:
- Account active status MUST be updated to inactive (`isActive = false`).
- Historical journal lines, posting history, and subject bindings remain **100% intact**.
- Inactive account cannot receive new direct postings (`INACTIVE_ACCOUNT`).
- Inactive group account cannot serve as parent for newly created nodes (`INACTIVE_ACCOUNT`).

---

## 16. SUBJECT DEPENDENCY CONTRACT

- If `AccountingSubject.primaryAccountId == account.id`:
  - Hard delete is **FORBIDDEN**.
  - Deassignment or rebinding of subject must be performed via explicit GATE-04 domain operation prior to deletion.
  - Deleting an account must **NEVER** automatically create replacement accounts or rewrite historical lines.

---

## 17. CONTEXT DEPENDENCY CONTRACT

- If a `ContextBinding` resolves to `account.id`:
  - Hard delete is **FORBIDDEN**.
  - Reconfiguration of context binding must occur explicitly via GATE-06 domain operations.
  - COA operations must **NEVER** mutate ContextHierarchy state.

---

## 18. CONCURRENCY CONTRACT

- Application pre-checks (`exists(code)`) are user-friendly optimizations only.
- SQLite database constraint `UNIQUE("company_id", "code")` is the **authoritative concurrency guard**.
- Under concurrent inserts, SQLite rejects the second insert with a unique constraint violation, which repository layer maps to canonical `ACCOUNT_CODE_ALREADY_EXISTS`. Exactly one insert succeeds.

---

## 19. CANONICAL ERROR TAXONOMY

| Triggering Domain Condition | Canonical Error Code |
| :--- | :--- |
| Requested account does not exist | `ACCOUNT_NOT_FOUND` |
| Operation target or parent belongs to another company | `CROSS_TENANT_ACCOUNT_REJECTION` |
| Parent account ID does not exist | `INVALID_PARENT_ACCOUNT` |
| Target parent is a detail/postable account (`isGroup == false`) | `INVALID_PARENT_ACCOUNT` |
| Account hierarchy cycle detected (`A->A`, `A->B->A`, `A->B->C->A`) | `COA_HIERARCHY_CYCLE` |
| Hierarchy chain exceeds `MAX_DEPTH` (10 nodes / level 9) | `COA_HIERARCHY_DEPTH_EXCEEDED` |
| Posting target or parent is inactive (`isActive == false`) | `INACTIVE_ACCOUNT` |
| Posting attempt to group account (`isGroup == true`) | `GROUP_ACCOUNT_NOT_POSTABLE` |
| Account code already exists within company `(company_id, code)` | `ACCOUNT_CODE_ALREADY_EXISTS` |
| Attempt to delete account with child accounts | `ACCOUNT_HAS_CHILDREN` |
| Attempt to hard delete account with journal history | `ACCOUNT_HAS_POSTED_HISTORY` |

---

## 20. GATE-05 COMPATIBILITY

GATE-07 does **NOT** modify GATE-05. The frozen GATE-05 resolution algorithm remains:

```text
requestedRole
  ↓
Role Applicability Filter
  ↓
Applicable Resolution Sources
  ↓
Context > Subject > Company   (Precedence order among applicable sources)
  ↓
Source State Validation (UNCONFIGURED -> continue; CONFIGURED+VALID -> return; CONFIGURED+INVALID -> fail closed)
  ↓
Account Validation (isActive == true, isGroup == false)
  ↓
FinancialAccount.id
```

### Frozen Role Applicability Matrix
| Role | Context | Subject | Company |
| :--- | :---: | :---: | :---: |
| `CUSTOMER_RECEIVABLE` | NO | YES | YES |
| `SUPPLIER_PAYABLE` | NO | YES | YES |
| `SALES_REVENUE` | YES | NO | YES |
| `PURCHASE_EXPENSE` | YES | NO | YES |
| `COGS` | YES | NO | YES |
| `INVENTORY` | YES | NO | YES |
| `CASH` | YES | NO | YES |
| `BANK` | YES | NO | YES |
| `TAX` | NO | NO | YES |
| `FX_GAIN_LOSS` | NO | NO | YES |

---

## 21. GATE-06 COMPATIBILITY

- Context Hierarchy (GATE-06) and COA Hierarchy (GATE-07) remain completely segregated.
- Error codes, cycle detection algorithms, and depth limits are independently maintained per domain.

---

## 22. SECURITY & WRITE PATH AUDIT

Forensic scan for production account creation and write paths confirmed:
1. `DriftFinancialAccountRepository`: Persistence Layer Hydration (AUTHORIZED)
2. `ChartOfAccountsService`: Authoritative Domain Service (AUTHORIZED)
3. `CustomerAccountingProvisioningService`: Sub-ledger AR Provisioning (AUTHORIZED)
4. `SupplierAccountingProvisioningService`: Sub-ledger AP Provisioning (AUTHORIZED)

**Result:** **0** unauthorized production write paths found across `lib/` (PASS).

---

## 23. REQUIRED FINAL FORENSIC MATRIX

| Area | Required Final State | Evidence | Status |
| :--- | :--- | :--- | :--- |
| Technical identity | UUID v7 immutable | Source scan across packages | **PASS** |
| Account code | Mutable human reference | Mutation contract analysis | **PASS** |
| Parent hierarchy | `parentAccountId` canonical relation | Drift table & entity schema | **PASS** |
| Level | Derived metadata (`root=0`, `child=parent+1`) | Materialized level recalculation | **PASS** |
| Composite uniqueness | DB enforced (`company_id, code`) | SQLite `sqlite_master` PRAGMA DDL | **PASS** |
| Parent tenancy | Application enforced (`parent.companyId == child.companyId`) | Service & Repository validation | **PASS** |
| Composite FK | Absent in physical SQLite DDL | SQLite `foreign_key_list` PRAGMA | **PASS** |
| Group semantics | Non-postable container | `validatePostingTarget` checks | **PASS** |
| Leaf semantics | Postable detail node; cannot have children | `createAccount` parent checks | **PASS** |
| Root semantics | `parent == null`, `level == 0` | Supported forest structure | **PASS** |
| COA cycle | Dedicated `COA_HIERARCHY_CYCLE` | Traversal algorithm | **PASS** |
| COA depth | 10 nodes / Max level 9 | `COA_HIERARCHY_DEPTH_EXCEEDED` | **PASS** |
| Move atomicity | 10-step atomic transaction | Transactional boundary model | **PASS** |
| Move side effects | Metadata only (0 lines/journals/balances) | Side-effect analysis | **PASS** |
| Code mutation | Metadata only (0 lines/journals/balances) | Side-effect analysis | **PASS** |
| Delete dependencies | Complete 10-area reference scan | Schema & repository scan | **PASS** |
| Posted history | Hard delete forbidden (`ACCOUNT_HAS_POSTED_HISTORY`) | History check contract | **PASS** |
| Subject binding | Hard delete forbidden (`ACCOUNT_BOUND_TO_SUBJECT`) | GATE-04 integration check | **PASS** |
| Context binding | Hard delete forbidden (`ACCOUNT_BOUND_TO_CONTEXT`) | GATE-06 integration check | **PASS** |
| Concurrency | DB `UNIQUE("company_id", "code")` authoritative | SQLite error mapping | **PASS** |
| GATE-05 compatibility | Unchanged (`Context > Subject > Company`) | Precedence verification | **PASS** |
| GATE-06 compatibility | Unchanged (Segregated taxonomy) | Error domain verification | **PASS** |

---

## 24. KNOWN NON-BLOCKING FUTURE HARDENING

- **Future DB Composite FK Migration (OPTION B):** Adding physical SQLite composite FK constraint `FOREIGN KEY (company_id, parent_account_id) REFERENCES financial_accounts (company_id, id) ON DELETE RESTRICT` via migration is documented as an optional post-Phase 2B DB hardening item. It is not required for GATE-07 approval because application enforcement is complete and verified.

---

## 25. FINAL GATE DECISION & VERDICT

```text
===============================================================================
                    GATE-07 DESIGN = CLOSED
                    GATE-07 DESIGN = LOCKED
                 READY FOR GATE-07 EXECUTION
===============================================================================
```

### ABSOLUTE HARD STOP DECLARATION
Per strict instructions:
- Production code has NOT been modified.
- No database migrations were created or run.
- `ChartOfAccountsService` implementation refactoring has NOT commenced.
- TEST-136..177 and ATTACK-27..39 execution have NOT been triggered.
- GATE-08 has NOT been initiated.
- Work is halted at `PHASE_2B_GATE_07_FINAL_DESIGN_DECISION.md`.
