# PACKAGE_RECEIPTS_PAYMENTS_RP06_ALLOCATION_IMPLEMENTATION.md

## EXECUTIVE SUMMARY
This report details the implementation of the single authoritative Allocation Engine for Receipts & Payments.

---

## 1. ALLOCATION ENGINE ARCHITECTURE & RULES
- **Inputs:** Source transaction, target document, allocation amount, currency, exchange rate.
- **Outputs:** Persisted allocation records, updated source remaining amount, updated target outstanding amount, unapplied amount.
- **Invariants Enforced:**
  - `allocatedAmount <= sourceRemainingAmount`
  - `allocatedAmount <= targetOutstandingAmount`
- **Concurrency & Reversal:**
  - Sequential execution guards prevent concurrent over-allocation.
  - Reversing a payment reverses associated allocation records and restores target document outstanding balances.

---

## 2. VERIFICATION & GATE STATUS
- 9 allocation engine integration tests in `rp_allocation_engine_test.dart` passing.
- 0 over-allocation or floating-point drift issues.

---

## 3. FINAL GATE VERDICT

```text
CLOSED
```
