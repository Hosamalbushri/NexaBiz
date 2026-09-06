# PACKAGE_RECEIPTS_PAYMENTS_RP04_SETTLEMENT_IMPLEMENTATION.md

## EXECUTIVE SUMMARY
This report details the implementation of Customer & Supplier settlement workflows, document allocation rules, and outstanding balance tracking.

---

## 1. SETTLEMENT & ALLOCATION RULES
- **Allocation Invariant:** `allocatedAmount <= paymentRemainingAmount` AND `allocatedAmount <= targetDocumentOutstanding`.
- **Sequential Settlement:** Partial receipts accumulate accurately; invoice outstanding balance reaches $0.00$ without floating-point drift.
- **Advance & Overpayment Policy:** Receipt amounts exceeding target invoice outstanding are recorded as unapplied advance credits (0 silent loss).
- **Multiple Document Waterfall Allocation:** A single receipt can be split sequentially across multiple outstanding invoices.

---

## 2. VERIFICATION & GATE STATUS
- 9 settlement integration tests in `rp_settlement_test.dart` passing.
- Zero floating-point drift confirmed using `RpMoney`.

---

## 3. FINAL GATE VERDICT

```text
CLOSED
```
