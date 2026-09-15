# PHASE 2B — GATE-04 CLOSURE REPORT

## Executive Summary
**GATE:** Phase 2B GATE-04 (Subject Account Binding Semantics)  
**STATUS:** CLOSED  
**VERDICT:** **GATE-04 = CLOSED**  
**DATE:** 2026-09-14  
**SUITE TEST RESULT:** 100% Passed (78/78 tests across 13 financial test files)

---

## 1. Authoritative Binding Architecture Decision
- **Authoritative Model:** **`AccountingSubject.primaryAccountId`** (stored in `financial_subjects.primary_account_id`).
- **Decision Document:** `PHASE_2B_SUBJECT_ACCOUNT_BINDING_DECISION.md`
- **Cardinality:** **ONE_TO_ONE** (per `AccountingSubject`).
- **Derived Multi-Currency Projection:** `FinancialSubjectAccountBuckets` (`financial_subject_account_buckets`) is strictly a **DERIVED MULTI-CURRENCY SUB-LEDGER PROJECTION** tracking currency balances per `(companyId, subjectId, accountId, currencyCode)` from posted `JournalLine` entries.
- **Service Authority:** `SubjectAccountBindingService` (`lib/packages/financial/domain/binding/subject_account_binding_service.dart`) acts as the single domain gateway for canonical binding creation, resolution, and reassignment.

---

## 2. Physical Schema Evidence
- **Table `financial_subjects`:**
  - Primary Key: `id` (UUID v7, 36 chars)
  - Foreign Keys / Constraints: Unique `{companyId, id}` and `{companyId, subjectType, code}`
  - Binding Column: `primaryAccountId` (UUID v7, 36 chars referencing `financial_accounts(id)`)
- **Table `financial_subject_account_buckets`:**
  - Unique Key: `{companyId, subjectId, accountId, currencyCode}`
  - Balance Storage: `balanceScaled` (Int64 scaled by 10^8)

---

## 3. Implementation Evidence
- [NEW] `lib/packages/financial/domain/binding/subject_account_binding_service.dart`
- [MODIFY] `lib/packages/financial/domain/provisioning/customer_accounting_provisioning_service.dart`
- [MODIFY] `lib/packages/financial/domain/provisioning/supplier_accounting_provisioning_service.dart`
- [MODIFY] `lib/packages/financial/infrastructure/repositories/financial_subject_repository.dart`
- [MODIFY] `lib/packages/financial/infrastructure/persistence/drift_financial_repositories.dart`
- [NEW] `test/packages/financial/financial_gate04_subject_account_binding_test.dart`
- [NEW] `PHASE_2B_SUBJECT_ACCOUNT_BINDING_DECISION.md`
- [NEW] `PHASE_2B_GATE_04_CLOSURE_REPORT.md`

---

## 4. Binding Lifecycle & Invariants
- **Creation (`bindSubjectToAccount`):** Validates company context, active states of subject and account, and role compatibility. Idempotent: returns existing binding if already bound.
- **Resolution (`resolveSubjectAccount`):** Returns technical `FinancialAccount.id` (UUID v7). Fail-closed with `MISSING_SUBJECT_ACCOUNT_BINDING` if unlinked. **NO HIDDEN ACCOUNT-CODE FALLBACKS**.
- **Reassignment (`reassignSubjectAccount`):** Updates binding to new account ID. **0** journal entries created, **0** balance transfers, and historical `JournalLine` entries remain 100% immutable.
- **Account Number Decoupling:** Changing `FinancialAccount.code` (e.g., `120001` -> `121001`) modifies display code only; technical `id` and binding remain unchanged.
- **Account Move Semantics:** Moving an account under a new parent preserves the binding `Subject -> Account.id` unchanged.

---

## 5. Test Matrix & Adversarial Results

### 5.1 GATE-04 Test Cases (`test/packages/financial/financial_gate04_subject_account_binding_test.dart`)
- `TEST-43`: Canonical subject -> account binding creation — **PASSED**
- `TEST-44`: Duplicate identical binding returns existing — **PASSED**
- `TEST-45 & TEST-49`: Cross-company subject/account binding rejection (Attack A) — **PASSED**
- `TEST-46`: Cross-company subject binding under wrong company context (Attack B) — **PASSED**
- `TEST-47`: Invalid role rejection — **PASSED**
- `TEST-48`: Inactive account rejection — **PASSED**
- `TEST-50 & TEST-52`: Customer provisioning creates canonical binding & is idempotent — **PASSED**
- `TEST-51 & TEST-53`: Supplier provisioning creates canonical binding & is idempotent — **PASSED**
- `TEST-54`: Account code mutation preserves binding identity — **PASSED**
- `TEST-55`: Account move under new parent preserves binding identity — **PASSED**
- `TEST-56`: Reassignment preserves historical JournalLines immutability — **PASSED**
- `TEST-58 & TEST-59`: Resolver returns technical UUID v7 identity and never human code — **PASSED**
- `TEST-60`: Missing binding fails explicitly without silent fallback — **PASSED**
- `TEST-61`: Multi-role Customer + Supplier remains 100% isolated — **PASSED**

### 5.2 Financial Package Full Suite Summary
- **Files Tested:** 13 test files
- **Total Tests:** 78
- **Passed:** 78
- **Failed:** 0
- **Pass Rate:** **100%**

---

## 6. Final Verdict & Boundary Compliance
Phase 2B GATE-04 is **CLOSED & LOCKED**.
All hard rules satisfied. Execution stopped prior to GATE-05.
