# PHASE 2B — SUBJECT ACCOUNT BINDING ARCHITECTURAL DECISION

## 1. Selected Authoritative Model
```text
SELECTED AUTHORITATIVE MODEL: MODEL A — FinancialSubject.primaryAccountId
```

### Clarification & Non-Ambiguity
- `AccountingSubject.primaryAccountId` (stored in SQLite table `financial_subjects.primary_account_id`) is the **SINGLE AUTHORITATIVE SOURCE OF TRUTH** for the `Subject → FinancialAccount` binding.
- There is **NO** secondary or conflicting table for primary subject bindings.
- `SubjectAccountBucket` (`financial_subject_account_buckets`) is classified strictly as a **DERIVED MULTI-CURRENCY SUB-LEDGER PROJECTION** tracking currency balances per `(companyId, subjectId, accountId, currencyCode)` from posted `JournalLine` entries.
- Any secondary domain service or port (`SubjectAccountBindingService`) resolves bindings directly against `AccountingSubject.primaryAccountId` enforcing strict tenant `companyId` boundaries.

---

## 2. Selected Cardinality
```text
SELECTED CARDINALITY: ONE_TO_ONE (per AccountingSubject)
```

- Each `AccountingSubject` entity is bound 1:1 to exactly **ONE** primary `FinancialAccount` (`primaryAccountId`).
- **Multi-Role Parties (Customer + Supplier):**
  If a single real-world party acts as both a Customer and a Supplier, NexaBiz provisions **TWO** distinct `AccountingSubject` entities:
  1. `AccountingSubject` (subjectType: `CUSTOMER`) -> Dedicated Customer `FinancialAccount` (Asset, e.g. `120001`)
  2. `AccountingSubject` (subjectType: `SUPPLIER`) -> Dedicated Supplier `FinancialAccount` (Liability, e.g. `210001`)
- This guarantees that Customer and Supplier accounting roles remain 100% isolated and never collapse or share a primary account.

---

## 3. Role Semantics
NexaBiz defines canonical subject role keys mapped directly to `AccountingSubjectType` and `FinancialAccountType`:

| Role Key | Subject Type | Required Account Type | Account Role | Cardinality | Company Scope |
|---|---|---|---|---|---|
| `CUSTOMER_RECEIVABLE` | `CUSTOMER` | `ASSET` | `RECEIVABLE` | 1:1 | Enforced |
| `SUPPLIER_PAYABLE` | `SUPPLIER` | `LIABILITY` | `PAYABLE` | 1:1 | Enforced |
| `OTHER_SUBJECT` | `OTHER` | `ASSET` / `LIABILITY` / `EXPENSE` | `OTHER` | 1:1 | Enforced |

---

## 4. Invariants & Lifecycle Rules

### 4.1 Tenancy Invariant
```text
binding.companyId == subject.companyId == account.companyId
```
- Any cross-company binding attempt (e.g. Company A Subject + Company B Account) MUST fail closed with `FinancialValidationException` or return `null`.

### 4.2 Account Number Decoupling
- Binding identity is strictly `FinancialAccount.id` (UUID v7).
- Account code mutation (e.g., `120001` -> `121001`) modifies display code only; technical `id` and binding remain unchanged.

### 4.3 Non-Financial Account Move
- Moving an account under a new parent (e.g., changing `parentAccountId` from `1200` to `1210`) is a structural metadata operation.
- The binding `Subject -> Account.id` remains unchanged.
- **ZERO** journal entries are generated, **ZERO** balance transfers occur, and historical `JournalLine` records are untouched.

### 4.4 Historical Immutability
- Historical `JournalLine` entries contain snapshot `accountId` and `subjectId` at the time of posting.
- Rebinding a subject or mutating account metadata NEVER rewrites past `JournalLine` records.

### 4.5 Archival & Deletion Lifecycle
- Archiving an active `FinancialAccount` with an active bound `AccountingSubject` prevents posting to that account while preserving historical journal integrity.
- Deleting a `FinancialAccount` that has active bound `AccountingSubject` references or posted `JournalLine` entries is strictly forbidden by database foreign key constraints (`RESTRICT` / fail-closed domain check).
