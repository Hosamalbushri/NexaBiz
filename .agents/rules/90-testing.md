# 90 — TESTING, VERIFICATION & ACCEPTANCE GOVERNANCE

## 1. Testing Philosophy
1. **Evidence-Based Acceptance**: A feature, bug fix, or refactoring is NOT considered complete until verified by an automated test suite demonstrating compliance with domain invariants.
2. **No Test Weakening**: Weakening, deleting, disabling, or commenting out existing failing tests to achieve green status is STRICTLY FORBIDDEN. Failing tests indicate broken business invariants that MUST be fixed in code.

---

## 2. Multi-Layer Testing Architecture
The verification system enforces eight mandatory testing layers:

```text
Unit
  ↓
Application
  ↓
Repository / Database
  ↓
Integration
  ↓
Production Path
  ↓
Regression
  ↓
Static Analysis
  ↓
Legacy / Reachability Scan
```

### Layer Definitions
1. **Unit Tests**: Verify isolated domain entities, value objects, domain logic, calculations, and pure helper functions.
2. **Application Tests**: Verify use cases, application service orchestrators, domain event handlers, and posting intent resolutions using mock ports.
3. **Repository / Database Tests**: Verify Drift SQL schema migrations, entity persistence, complex queries, foreign key cascades, and tenant filter compliance against encrypted SQLite in-memory databases.
4. **Integration Tests**: Verify end-to-end multi-module transaction flows (e.g., Sales Order → Inventory Movement → Accounting Journal → Audit Log).
5. **Production Path Verification**: Verify that production entry points (UI buttons, API endpoints, background handlers) successfully invoke the canonical implementation and not a legacy bypass.
6. **Regression Tests**: Protect fixed bugs against future regressions.
7. **Static Analysis**: Enforce strict Dart analyzer rules, null safety, and architecture linter constraints.
8. **Legacy / Reachability Scan**: Verify that replaced legacy code paths are deleted or completely unreachable in the production call graph.

---

## 3. Mandatory Testing Coverage Domains
Automated tests MUST explicitly cover the following critical areas:
* **Accounting Balance**: Verify that all generated journals satisfy `Debit == Credit` in both base and foreign currencies.
* **Tenant Isolation**: Verify that user/company A cannot read, update, or delete data belonging to company B.
* **Transaction Rollback**: Verify that failures mid-transaction cause 100% rollback across all participating entities.
* **Idempotency**: Verify that duplicate execution of posting operations results in identical system state without duplicate records.
* **Multi-Currency**: Verify conversion rate precision, missing rate handling, and anti-double-conversion invariants.
* **Negative Test Requirement**: Every feature test suite MUST include negative tests verifying that invalid inputs, locked periods, or missing permissions fail gracefully with expected errors.

---

## 4. Production Entry-Point Gate
1. **Unit Test Insufficiency**: Passing unit tests alone are INSUFFICIENT for task acceptance.
2. **Reachability Proof**: The developer/agent MUST prove that the production call graph successfully routes real application calls to the newly verified canonical implementation.
