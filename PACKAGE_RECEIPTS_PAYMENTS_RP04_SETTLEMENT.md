# RP-04 — CUSTOMER & SUPPLIER SETTLEMENT SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report defines the deterministic settlement and allocation engine for Receipts & Payments against Sales Invoices, Purchase Documents, Customer/Supplier Account Balances, and Advances. The engine enforces mathematically precise settlement, strict allocation bounds, non-discarding overpayment handling, and GL-derived balance integrity.

---

## 1. SETTLEMENT SCOPE & TYPES

### 1.1 Customer Receipt Settlement Modes
1. **Single Invoice Settlement:** Full or partial settlement against a specific Sales Invoice.
2. **Multi-Invoice Settlement:** Allocating a single receipt across multiple outstanding invoices sequentially or by user selection.
3. **Customer Account Balance Settlement:** Settle general open customer receivable account balance.
4. **Customer Advance Payment:** Unapplied receipt recorded as customer credit/advance.

### 1.2 Supplier Payment Settlement Modes
1. **Single Purchase Document Settlement:** Full or partial settlement against a specific Purchase Document.
2. **Multi-Document Settlement:** Allocating a single payment across multiple outstanding payables.
3. **Supplier Account Balance Settlement:** Settle general open supplier payable account balance.
4. **Supplier Advance Payment:** Unapplied payment recorded as vendor advance debit.

---

## 2. ALLOCATION DATA STRUCTURE & INVARIANTS

### 2.1 Allocation Record Identity
Every allocation must persist:
- `allocationUuid`: Unique identifier.
- `paymentTxnId` / `paymentTxnUuid`: Source receipt or payment document.
- `targetDocumentType` & `targetDocumentId`: Linked invoice/purchase document or account reference.
- `allocatedAmount`: Amount applied to the target.
- `currencyCode` & `exchangeRate`: Currency valuation at settlement time.
- `companyId`: Tenant isolation scoping.
- `allocatedAt`: Audit timestamp.

### 2.2 Strict Allocation Invariants
1. **Remaining Payment Bound:**
   $$\sum \text{allocatedAmount} \le \text{receipt/payment total amount}$$
2. **Outstanding Document Bound:**
   $$\text{allocatedAmount} \le \text{target document remaining outstanding amount}$$
3. **Zero Negative Allocation:**
   $$\text{allocatedAmount} > 0$$

---

## 3. PARTIAL SETTLEMENT & DECIMAL PRECISION

- **Sequential Reduction Formula:**
  $$\text{outstanding}_{\text{new}} = \text{outstanding}_{\text{previous}} - \text{allocatedAmount}$$
- **Zero Floating-Point Drift:** Rounding is performed at the standard monetary sub-unit level (e.g. 2 decimal places in `SAR`). Sequential partial receipts (e.g., 400 SAR followed by 600 SAR on a 1,000 SAR invoice) leave exactly `0.00` outstanding.

---

## 4. OVERPAYMENT & ADVANCE POLICY

- **Non-Discarding Principle:** If a payment/receipt amount exceeds the outstanding invoice total (e.g., Receipt = 1,200 SAR for a 1,000 SAR invoice), the unallocated 200 SAR MUST NOT be silently discarded.
- **Handling Strategy:**
  1. The 1,000 SAR portion settles the invoice.
  2. The remaining 200 SAR is categorized as an **Unapplied Customer Credit / Advance Payment**.
  3. The advance is available for future invoice application or explicit refund.

---

## 5. CUSTOMER & SUPPLIER BALANCE INTEGRITY

- **Direct UI Mutation Forbidden:** Neither UI components nor transient services may directly alter customer/supplier balance properties.
- **GL-Derived Source of Truth:**
  $$\text{Customer Balance} = \sum \text{Posted Debit Invoices} - \sum \text{Posted Credit Receipts}$$
  $$\text{Supplier Balance} = \sum \text{Posted Credit Bills} - \sum \text{Posted Debit Payments}$$

---

## 6. SETTLEMENT CANCELLATION & REVERSAL

- **Atomic Reversal:** Cancelling or unposting a posted receipt/payment atomically voids all linked `Allocation` records.
- **Outstanding Restoration:** Invoice / purchase document outstanding amounts are restored immediately upon transaction cancellation.

---

## 7. INTEGRATION TEST MATRIX (`test/modules/receipts_payments/rp_settlement_test.dart`)

1. **Full Settlement:** Single receipt fully settles an invoice.
2. **Partial Settlement:** Sequential partial receipts reduce outstanding to zero.
3. **Multi-Invoice Settlement:** Single receipt split across two distinct invoices.
4. **Multi-Payment Settlement:** Two receipts applied to the same invoice.
5. **Overpayment & Advance:** Receipt exceeding invoice amount creates advance credit.
6. **Customer Advance Payment:** Unapplied receipt creates customer credit.
7. **Invalid Allocation Guard:** Allocation exceeding remaining invoice outstanding is rejected.
8. **Duplicate Allocation Guard:** Re-posting duplicate allocation is prevented.
9. **Cancellation & Reversal:** Cancelling a receipt restores invoice outstanding balance.
