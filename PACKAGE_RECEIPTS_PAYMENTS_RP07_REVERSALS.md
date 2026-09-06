# RP-07 — REFUNDS, REVERSALS & CANCELLATION SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report details the architectural specification for non-destructive reversals, customer/supplier refunds, and cancellation controls within Receipts & Payments. The design mandates that posted economic transactions are never deleted; all corrections, reversals, and refunds are recorded as explicit offsetting entries that reference original transaction, journal, cash movement, and allocation IDs while preserving historical exchange rates.

---

## 1. NON-DESTRUCTIVE REVERSAL ARCHITECTURE

### Fundamental Immutability Constraint
- **No Hard Deletion:** SQL `DELETE` operations on posted `financial_transactions`, `journal_entries`, `stock_movements`, or `allocations` are strictly prohibited.
- **Controlled Reversal Entry:** Cancelling or reversing a transaction creates a new offsetting transaction:
  - `reversalTransactionUuid`: Explicit UUID pointing to `originalTransactionUuid`.
  - `originalJournalId`: Foreign key to original accounting journal.
  - `originalCashMovementId`: Foreign key to cash register / bank movement.
  - `originalAllocationId`: Foreign key to document allocation.

---

## 2. CUSTOMER & SUPPLIER REFUND LOGIC

- **Customer Refund:** A business payout returning money to a customer for a previously settled receipt or returned sale.
  - **Accounting:** DEBIT Customer Account, CREDIT Cash/Bank Account.
  - **Effect:** Reverses customer balance reduction caused by original receipt.
- **Supplier Refund:** A business receipt receiving money back from a supplier for a cancelled purchase or return.
  - **Accounting:** DEBIT Cash/Bank Account, CREDIT Supplier Account.
  - **Effect:** Reverses supplier balance reduction caused by original payment.

---

## 3. MULTI-MODULE SALES REFUND COORDINATION

When a Sales transaction is refunded, Receipts & Payments does NOT operate in isolation. The refund execution must coordinate across:

$$\text{Sales Return} \longrightarrow \text{Inventory Restored} \longrightarrow \text{COGS Reversed} \longrightarrow \text{Customer Credit} \longrightarrow \text{RP Refund} \longrightarrow \text{Cash Register Balance} \longrightarrow \text{Accounting GL}$$

- **Safety Guard:** Receipts & Payments checks if the associated Sales Return document is in `posted` state before issuing a cash refund to prevent orphaned cash payouts without inventory/COGS reversal.

---

## 4. REFUND BOUNDS & PARTIAL REFUND VALIDATION

For any transaction $T$ with original posted amount $A_{orig}$:
- **Tracking Parameters:**
  - `alreadyRefundedAmount`: Sum of previous non-cancelled refund allocations.
  - `remainingRefundableAmount`: $A_{orig} - \text{alreadyRefundedAmount}$.
- **Invariant:**
  $$\text{newRefundAmount} \le \text{remainingRefundableAmount}$$
- **Rejection:** Attempting to refund an amount exceeding `remainingRefundableAmount` throws `FinancialTransactionException.invalidAllocation`.

---

## 5. HISTORICAL CURRENCY RATE IMMUTABILITY

- **Exchange Rate Rule:** Refund and reversal entries MUST use the original transaction's exchange rate ($R_{orig}$), regardless of current exchange rate fluctuations.
- **No Rate Recalculation:** Historical base amounts are preserved exactly to ensure zero gain/loss leakage unless explicit FX settlement adjustments apply.

---

## 6. INTEGRATION TEST MATRIX (`test/modules/receipts_payments/rp_reversals_test.dart`)

1. **Full Refund Execution:** Single refund equal to original receipt amount.
2. **Partial Refund Execution:** Partial refund reducing remaining refundable amount.
3. **Repeated Partial Refund Execution:** Two sequential partial refunds settling total refundable amount.
4. **Excessive Refund Rejection Guard:** Attempting refund > remaining refundable amount is rejected.
5. **Transaction Cancellation Reversal:** Cancelling posted receipt creates reversal entry and restores state.
6. **Multi-Module Sales Refund Coordination:** RP refund coordinates with Sales/Inventory return.
7. **Foreign Currency Refund Execution:** Foreign currency refund processed at historical exchange rate.
8. **Historical Exchange Rate Preservation:** FX rate change does not alter refund calculation rate.
9. **Offline Reversal Persistence & Sync Invariance:** Offline reversal stored with original metadata.
