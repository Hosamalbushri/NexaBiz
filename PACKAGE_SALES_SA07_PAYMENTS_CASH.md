# SA-07 — Sales Payments & Cash Register Integration

## Overview
This document specifies the integration architecture between Sales, Cash Registers, and Treasury Receipts & Payments. It establishes single-source financial truth by linking sales settlements directly to designated Chart of Accounts (GL) accounts, preventing duplicate cash balances, enforcing multi-line payment split validations, guaranteeing posting idempotency, and governing atomic transaction reversals.

---

## 1. Supported Payment Methods
Sales settlements support the existing treasury architecture without inventing duplicate payment stores:
- **Cash:** Linked directly to an active, company-scoped Cash Register and its associated GL Cash Account.
- **Credit:** Billed directly to Customer Receivables without touching treasury cash balances.
- **Bank Transfer:** Mapped directly to an active Bank GL Account.
- **Card (POS):** Mapped directly to POS Clearing / Card GL Account.
- **Mixed Payment:** Split settlement allocations across multiple methods (e.g. Cash + Bank) matching the document total.

---

## 2. Cash Sale Execution Flow
When a cash sale is posted:
1. **Sale Document:** Status changes to `posted`.
2. **Revenue Journal Entry:**
   - `DEBIT`: Cash Register GL Account (increases cash balance dynamically derived from GL).
   - `CREDIT`: Sales Revenue Account (plus tax liabilities if applicable).
3. **Inventory Effect:**
   - Stock issue movement recorded (`decrease` stock).
   - Cost layers consumed via `CostLayerService`.
4. **COGS Journal Entry:**
   - `DEBIT`: COGS Account.
   - `CREDIT`: Inventory Asset Account.

---

## 3. Credit Sale Execution Flow
When a credit sale is posted:
1. **Customer Requirement:** Verified active, company-scoped customer with valid Customer Receivable GL Account.
2. **Revenue Journal Entry:**
   - `DEBIT`: Customer Receivable GL Account.
   - `CREDIT`: Sales Revenue Account.
3. **Treasury Invariant:** Treasury cash register balances are **NOT** modified or falsely increased.

---

## 4. Mixed Payment Allocation & Split Rules
- **Scenario:** Sale total = `100 SAR`, allocated as `40 SAR Cash` + `60 SAR Bank`.
- **Validation:** Total allocated payments ($\sum \text{Allocations}$) must equal the document net total ($\text{Sale Total}$).
- **Journal Line Generation:**
  - `DEBIT`: Cash Register Account (`40 SAR`)
  - `DEBIT`: Bank Account (`60 SAR`)
  - `CREDIT`: Sales Revenue (`100 SAR`)
- Overpayments or unallocated balance differences are strictly rejected.

---

## 5. Strict Payment Validation Rules
A sales transaction settlement is **REJECTED** if:
1. Any payment line amount is negative ($\le 0$).
2. Total payments do not match document total.
3. Cash register is invalid, unlinked, inactive, or belongs to a different company (`cross-company register`).
4. Required accounting accounts (Cash Account, Customer Receivable, Revenue, COGS, Inventory Asset) are missing or inactive.

---

## 6. Posting Idempotency Invariant
- Retrying a posting operation on an already posted sale document:
  - Returns the existing posted document and journal entry.
  - **MUST NOT** duplicate cash movements or double-increase cash register balances.
  - **MUST NOT** duplicate stock issue movements or re-consume cost layers.

---

## 7. Atomic Reversal & Voiding Integrity
Cancelling or voiding a paid sales transaction executes full atomic reversal across all integrated sub-systems:
1. **GL Revenue Entry Voiding:** Voiding/reversing revenue entry creates offsetting credit to Cash Register/Receivable account and debit to Revenue account.
2. **GL COGS Entry Voiding:** Reverses COGS debit and Inventory Asset credit.
3. **Inventory Reversal:** Invokes `costLayerService.reverseConsumptions(issueLineUuid)`, restoring layer remaining quantities and deleting consumption rows cleanly.
4. **Ledger Balance:** Dynamic cash register balance ($\text{Total Debit} - \text{Total Credit}$) immediately reflects the reversed cash movement without data drift.

---

## 8. Verification Matrix
Verified via `test/modules/sales/sales_payments_cash_test.dart` covering:
1. Cash sale integration (GL debit to cash account, revenue credit, stock issue, GL-derived cash balance increase).
2. Credit sale integration (GL debit to customer receivable, zero cash balance impact).
3. Mixed payment split allocation (Cash + Bank split matching total).
4. Payment validation rules (negative amounts, overpayments, unlinked/inactive registers, cross-company isolation).
5. Posting idempotency (retry posting returns existing entries without duplicate cash movement).
6. Full atomic reversal (voiding sale reverses cash movement, receivable, revenue, inventory, COGS).
