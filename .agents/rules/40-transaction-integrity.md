# 40 — TRANSACTION INTEGRITY & ATOMICITY

## 1. Application Transaction Boundary
1. **Cross-Domain Atomicity**: Any operation spanning multiple domain boundaries (e.g., operational commit + inventory movement + accounting journal commit + audit log + sync queue record) MUST execute within a single unified transaction boundary.
2. **Transaction Ownership**: Cross-domain transactions MUST be owned and orchestrated by Application Layer Use Cases or explicit Transaction Orchestrators. Repositories, presentation controllers, or UI widgets MUST NOT manage cross-domain transaction lifecycles.

---

## 2. Mandatory Transaction Invariants
1. **Atomic Posting Invariant**: If accounting integration is required for an operational event, the operational state update and accounting GL posting MUST succeed or fail together:

```text
Operational Commit (e.g., Invoice POSTED)
AND
Accounting Commit (e.g., Journal Entry POSTED)
```

2. **Forbidden Failure State**: The system MUST NEVER permit a state where an operational entity is marked `POSTED` while its corresponding accounting journal commit fails or is skipped:

```text
Forbidden State:
Operational Entity = POSTED
Accounting Journal = FAILED / SKIPPED
```

3. **Failure Semantics**: If any step within a transaction boundary throws an error or fails validation (e.g., period locked, unresolvable account, missing exchange rate, database lock), the ENTIRE transaction MUST roll back completely. Partial commits are strictly prohibited.

---

## 3. Inventory & Accounting Atomicity
1. **Cost Layer & GL Commit**: Inventory stock deduction/addition, cost layer consumption (FIFO/Average), operational stock movement record creation, and accounting inventory GL journal posting MUST commit atomically in a single local database transaction.
2. **Rollback Integrity**: If stock cost layer resolution fails or inventory availability validation fails, stock movements MUST NOT be persisted and no GL entries MAY be created.

---

## 4. Idempotency & Side-Effect Safety
1. **Idempotent Operations**: Retries of transaction posting (due to network disruption, sync collision, or UI double-click) MUST NOT create duplicate operational documents, stock movements, or GL journal entries.
2. **External Side Effects**: Side effects external to the local database transaction (e.g., REST API calls to Laravel backend, sending email notifications, printing physical receipts) MUST execute AFTER the local database transaction has successfully committed. External side-effect failures MUST NOT roll back already-committed local ACID transactions.

---

## 5. Sync & Audit Timing
1. **Audit Timing**: Audit log entries recording transactional actions MUST be created within the same database transaction boundary to guarantee non-repudiation.
2. **Sync Queue Invariant**: Outbound sync queue records (`sync_queue`) MUST be written atomically with local entity commits to prevent local data changes from occurring without an associated sync task.

---

## 6. Validation Purity & Testing Contracts
1. **Purity of Validation**: All domain validations (credit limit check, stock availability, rate existence, period lock, journal balance) MUST be evaluated BEFORE initiating database writes or transaction locks.
2. **Transaction Test Matrix**: Transaction orchestrators MUST be verified using unit and integration test suites that explicitly test rollback behavior on simulated failures across every step of the execution sequence.
