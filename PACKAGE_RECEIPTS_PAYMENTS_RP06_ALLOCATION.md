# RP-06 — ALLOCATION ENGINE & OUTSTANDING BALANCE INTEGRITY SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report defines the authoritative, deterministic Allocation Engine for Receipts & Payments. The engine computes document allocations, unapplied amounts, and remaining outstanding balances according to strict mathematical invariants, explicit audit trails, immutability rules, and reversal workflows.

---

## 1. AUTHORITATIVE ALLOCATION ENGINE ARCHITECTURE

### Deterministic Interface Definition
The Allocation Engine accepts structured inputs and deterministically computes output allocations without side effects or floating-point drift:

- **Inputs:**
  1. `sourcePayment`: Financial transaction (Receipt / Payment) with total amount $A_{payment}$ and currency $C_{payment}$.
  2. `targetDocuments`: Ordered list of target invoices/bills $D_1, D_2, \dots, D_n$ with outstanding amounts $O_1, O_2, \dots, O_n$.
  3. `requestedAllocations`: Map of target document ID to requested allocation amount $a_i$.
  4. `currency` & `exchangeRate`: Currency valuation metadata.

- **Outputs:**
  1. `allocations`: Validated list of `AllocationRecord` entities.
  2. `totalAllocated`: $\sum_{i=1}^n a_i$.
  3. `unappliedAmount`: $A_{payment} - \text{totalAllocated}$.
  4. `remainingOutstanding`: Map of target document ID to updated outstanding amount $O_i - a_i$.

---

## 2. CORE DETERMINISTIC INVARIANTS

1. **Payment Capacity Limit:**
   $$\sum_{i=1}^n a_i \le A_{payment}$$
2. **Document Outstanding Limit:**
   $$\forall i, \quad 0 \le a_i \le O_i$$
   *(Unless explicitly configured for overpayment/advance).*
3. **Non-Negative Allocation:**
   $$\forall i, \quad a_i > 0$$

---

## 3. MULTI-DOCUMENT WATERFALL ALLOCATION EXAMPLE

### Scenario Setup
- **Payment Amount:** `1,000 SAR`
- **Target Invoices:**
  - Invoice A: Outstanding `400 SAR`
  - Invoice B: Outstanding `300 SAR`
  - Invoice C: Outstanding `200 SAR`

### Allocation Output
- **Allocated to Invoice A:** `400 SAR` (Invoice A Outstanding $\rightarrow$ `0 SAR`)
- **Allocated to Invoice B:** `300 SAR` (Invoice B Outstanding $\rightarrow$ `0 SAR`)
- **Allocated to Invoice C:** `200 SAR` (Invoice C Outstanding $\rightarrow$ `0 SAR`)
- **Total Allocated Amount:** `900 SAR`
- **Remaining Unapplied Amount:** `100 SAR` (Recorded as unapplied customer advance)

---

## 4. IMMUTABILITY & REVERSAL WORKFLOW

- **Immutability Invariant:** Posted allocations are immutable historical records. They MUST NOT be edited or deleted directly from database tables.
- **Reversal Mechanism:** Reversing or cancelling a payment generates explicit **Allocation Reversal Entries**:
  - `reversalRecord`: Linked to `originalAllocationUuid`, with negative allocation magnitude or `isReversal: true`.
  - **Outstanding Restoration:** Invoice outstanding balance is restored ($O_{new} = O_{current} + a_i$).
  - **Audit History:** Full history of creation and reversal is preserved for audit trails.

---

## 5. CONCURRENCY & IDEMPOTENCY PROTECTION

- **Atomic Execution:** Allocation creation and document balance updates are performed within a single database transaction.
- **Idempotency Guard:** Retrying an allocation with an identical idempotency key or already-allocated payment UUID is rejected with `FinancialTransactionException.invalidAllocation`.
- **Optimistic Locking:** Simultaneous allocations targeting the same document verify that $O_{current}$ has not changed during transaction execution.

---

## 6. INTEGRATION TEST MATRIX (`test/modules/receipts_payments/rp_allocation_engine_test.dart`)

1. **Full Allocation:** Payment fully settles a target document.
2. **Partial Allocation:** Payment partially settles a target document.
3. **Multi-Document Sequential Allocation:** 1,000 SAR payment across Invoices A (400), B (300), C (200) $\implies$ 900 SAR allocated, 100 SAR unapplied.
4. **Multiple Payments to Single Document:** Two distinct payments allocated to one invoice.
5. **Overpayment & Unapplied Balance:** Payment exceeding total target outstanding recorded as unapplied credit.
6. **Unapplied Advance Payment Creation:** Zero target documents $\implies$ 100% unapplied advance credit.
7. **Reversal Audit Workflow:** Reversing payment creates explicit reversal records without deleting original allocations.
8. **Duplicate Allocation Prevention:** Re-posting duplicate allocation is prevented.
9. **Concurrent Allocation Safety:** Simultaneous allocations safely process sequentially.
