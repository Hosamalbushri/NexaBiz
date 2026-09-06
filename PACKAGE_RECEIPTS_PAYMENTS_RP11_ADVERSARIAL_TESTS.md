# RP-11 — RECEIPTS & PAYMENTS ADVERSARIAL TEST SUITE SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report details the adversarial audit and test suite designed to attack the Receipts & Payments module across 8 critical risk vectors: Domain Invariants, Allocation Limits, Accounting Double-Entry GL, Cash Register Integration, Multi-Currency FX, Reversals & Refunds, Offline Sync & Idempotency, and Multi-Tenant Security.

---

## 1. ADVERSARIAL TEST GROUPS

### Group 1: Domain Invariants
- **Invalid State Transitions:** Attempting to post a cancelled transaction or edit a posted transaction.
- **Duplicate Posting Attack:** Re-submitting post requests on an already posted voucher.
- **Invalid Amounts:** Zero ($0.00$) or negative ($-500.00$) amounts.
- **Invalid Currency:** Unrecognized or empty currency codes.
- **Missing Account:** Null/empty cash account or counter account.

### Group 2: Allocation Boundaries
- **Over-Allocation Attack:** Attempting to allocate an amount exceeding target document outstanding.
- **Duplicate Allocation Attack:** Re-posting an existing allocation record.
- **Concurrent Allocation Attack:** Two devices attempting to allocate against the same invoice balance concurrently.
- **Partial Settlement:** Sequential receipts (400 SAR + 600 SAR against 1000 SAR invoice) correctly updating outstanding balance to $0.
- **Exceeding Allocation Rejection (Numerical Test):** 3rd receipt of 100 SAR against fully settled invoice ($0$ outstanding) is strictly REJECTED (or treated as advance credit).

### Group 3: Accounting GL Integrity
- **Unbalanced Journal Attack:** Posting a entry with unequal base debits and credits ($\sum \text{Debit}_{base} \ne \sum \text{Credit}_{base}$).
- **Duplicate Journal Attack:** Retrying a posting resulting in duplicate GL journal entries.
- **Wrong Account / Company:** Routing GL lines to accounts belonging to another tenant.

### Group 4: Cash Register & Treasury Integrity
- **Wrong Register Attack:** Attempting cash receipt into a non-existent cash register ID.
- **Inactive Register Attack:** Posting cash transaction to an inactive/closed register.
- **Cross-Company Register Attack:** Posting cash transaction for Company A to Company B's register.
- **Duplicate Cash Movement:** Retrying posting generating duplicate cash balance movements.

### Group 5: Multi-Currency & FX Integrity
- **Missing / Zero FX:** Foreign currency transaction with $FX_{rate} \le 0$.
- **Inverted / Changed FX:** Recalculating historical transaction using today's spot rate.
- **Rounding Drift:** Precision loss during multi-currency conversion.
- **Foreign Settlement Numerical Test:** 10 USD invoice @ 1250 YER/USD settled by 3,750 YER receipt $\implies$ 3 USD settled, 7 USD remaining.

### Group 6: Reversals & Refunds
- **Double Reversal Attack:** Attempting to reverse an already reversed receipt/payment.
- **Excessive Refund Attack:** Refunding an amount greater than the original receipt amount.
- **Partial Refund:** Partial reversal correctly updating remaining refundable balance.
- **Reversed Allocation:** Reversing payment correctly restores original target document outstanding balance.

### Group 7: Offline Sync & Idempotency
- **Duplicate Sync Retry:** Re-transmitting offline sync payload 3 times.
- **Restart & Conflict:** Restarting application mid-sync with un-acknowledged records.

### Group 8: Multi-Tenant Security
- **Cross-Company IDs:** Accessing Company B documents using Company A context.
- **Unauthorized Account / Register / Customer:** Accessing cross-company accounts or counterparties.

---

## 2. NUMERICAL & CURRENCY ADVERSARIAL TEST RESULTS

### Sequential Allocation Test (1,000 SAR Invoice)
| Step | Action | Amount | Document Outstanding | Result |
| :--- | :--- | :--- | :--- | :--- |
| 1 | Invoice Creation | — | 1,000.00 SAR | Created |
| 2 | Receipt #1 | 400.00 SAR | 600.00 SAR | **PASSED** |
| 3 | Receipt #2 | 600.00 SAR | 0.00 SAR | **PASSED** |
| 4 | Receipt #3 (Attack) | 100.00 SAR | 0.00 SAR | **REJECTED** (Over-allocation guard enforced) |

### Multi-Currency FX Settlement Test (10 USD Invoice)
| Layer | Amount / Rate | Document Outstanding | Result |
| :--- | :--- | :--- | :--- |
| **Invoice** | 10.00 USD | 10.00 USD | Created |
| **Historical FX** | 1 USD = 1,250 YER | — | Persisted |
| **Receipt Payload** | 3,750.00 YER | — | Converted at historical FX |
| **Settlement** | 3.00 USD equivalent | **7.00 USD remaining** | **PASSED** |
