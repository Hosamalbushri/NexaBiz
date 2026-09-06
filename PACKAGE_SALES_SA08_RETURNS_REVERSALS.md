# SA-08 — Sales Returns, Cancellation & Reversal Integrity

## Overview
This document specifies the domain standards and architectural rules governing controlled corrections, returns, and cancellations of posted Sales transactions. Direct mutation of posted economic history is strictly prohibited; all adjustments are recorded via explicit return documents or controlled journal and inventory reversals.

---

## 1. Return Document Identity & Mandatory References
Every sales return document must reference the original sale:
- `originalSaleUuid`: UUID of the posted original sale invoice.
- `originalSaleLineId`: UUID of the specific line item returned.
- `returnedQuantity`: Exact quantity being returned.
- `warehouseId`: Explicitly selected return warehouse.
- `customerId`: Customer account context matching original sale.
- `currencyCode`, `baseCurrencyCode`, `exchangeRate`: Preserved original exchange rate parameters.

---

## 2. Return Quantity Tracking & Validation Invariants
- The system maintains strict returnable quantity tracking per sale line:
  $$\text{Remaining Returnable Quantity} = \text{Sold Quantity} - \sum \text{Already Returned Quantity}$$
- **Invariant:** $\text{Returned Quantity} \le \text{Remaining Returnable Quantity}$.
- Any attempt to return a quantity exceeding remaining returnable quantity is **STRICTLY REJECTED** with a controlled exception (`SaleException.excessiveReturn`).

---

## 3. Explicit Warehouse Selection for Returns
- Returned inventory enters the warehouse explicitly specified on the return document (`warehouseId`).
- **Forbidden:** The system must **NEVER** infer, guess, or default to global or first warehouse.

---

## 4. COGS Reversal & Historical Valuation Fidelity
- COGS reversal for returned items uses the original unit cost recorded in consumed inventory cost layers.
- **Rule:** The system **MUST NOT** evaluate current FIFO, LIFO, or WAC rates to recalculate historical COGS upon return.
- Restored inventory layers are created or reopened using `costLayerService.reverseConsumptions(issueLineUuid)` or new cost layers using the original receipt unit cost.

---

## 5. Financial Refunds & Accounting Entry Drafts
- **Credit Sale Returns:**
  - `DEBIT`: Sales Returns / Sales Revenue Account.
  - `CREDIT`: Customer Receivable Account (`customerAccountId`).
- **Cash / Paid Sale Returns:**
  - `DEBIT`: Sales Returns / Sales Revenue Account.
  - `CREDIT`: Cash Register / Payment Account (`cashAccountId`).
- **Pricing & FX Snapshot:** Refund calculations utilize the original transaction unit price and original exchange rate snapshot (`exchangeRate`), unaffected by subsequent catalog price or market FX changes.

---

## 6. Controlled Cancellation & Voiding Rules
- Cancelling a posted sale executes controlled reversal:
  1. Invokes `journalPostingService.voidBySource(sourceType: 'sale', sourceId: saleUuid)`.
  2. Invokes `journalPostingService.voidBySource(sourceType: 'sale_cogs', sourceId: saleUuid)`.
  3. Invokes `costLayerService.reverseConsumptions(issueLineUuid)`.
- **Invariant:** Posted sale records are **NEVER** hard-deleted from the database (`deletedAt` soft-delete or `cancelledAt` status timestamp is updated).

---

## 7. Verification Matrix
Verified via `test/modules/sales/sales_returns_reversals_test.dart` covering:
1. Full return (100% of sold item returned).
2. Partial return (partial quantity returned, updating remaining returnable qty).
3. Repeated returns (sequential partial returns until remaining returnable qty is 0).
4. Excessive return rejection (attempting return quantity > remaining returnable qty).
5. Return after price change (preserving original sale line unit price).
6. Return after FX change (preserving original exchange rate snapshot).
7. Return after costing policy change (reversing original layer valuation cost).
8. Return to different warehouse (restoring stock to explicit return warehouse).
9. Cash refund vs Credit refund GL line account assignment.
10. Full transaction cancellation (controlled reversal without row deletion).
