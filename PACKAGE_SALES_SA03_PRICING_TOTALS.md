# SA-03 — Sales Lines, Pricing, Discounts & Deterministic Totals

## Overview
This document specifies the domain rules, pricing engine, discount evaluation, and deterministic calculation rules for Sales line items and document-level totals in the NexaBiz ERP system.

---

## 1. Sales Line Identity & Quantities
Every line on a sales document represents an individual product line item with strict identity constraints:

- **Identity Attributes:**
  - `productId`: Opaque UUID reference to the product entity.
  - `warehouseId`: Warehouse origin for inventory deduction (inherited from document or specified per line).
  - `quantity`: Effective billing quantity (`mainQuantity + (subQuantity / packSize)`).
  - `mainQuantity` / `subQuantity` / `packSize`: Multi-unit inventory packaging properties.
  - `unitPrice`: Unit selling price in document currency.
  - `baseUnitPrice`: Catalog unit price in company base currency.

- **Quantity Validation Rules:**
  - Rejects zero quantity (`quantity <= 0`).
  - Rejects negative quantities.
  - Enforces pack size normalization (`packSize >= 1`).
  - Uses `SaleQuantityMath` to handle fractional quantities without floating-point precision loss.

---

## 2. Pricing & Manual Price Overrides
- **Domain-Owned Pricing:**
  - Price resolution is governed by domain rules (`SaleValidator` & `SaleCurrencyConverter`).
  - UI values are non-authoritative and must pass validation before persistence.
- **Price Validation & Overrides:**
  - `unitPrice >= 0` and `baseUnitPrice >= 0`.
  - Prices below catalog minimum are validated against authorization rules (`SaleException.priceBelowCatalog`).
  - Overrides are explicitly recorded in `unitPrice` and preserved in persistent snapshots.

---

## 3. Canonical Discount Engine
Discounts are calculated using a single, centralized domain implementation (`SaleMoney.applyDiscount`):

- **Supported Types:**
  - `DiscountType.percentage`: Calculated as `(baseCents * percentage) / 100`. Validated to satisfy `0 <= percentage <= 100`.
  - `DiscountType.fixed`: Calculated as monetary value in document currency. Validated to be non-negative (`fixed >= 0`).
- **Discount Safety & Clamping:**
  - `discountAmount` is capped at line/document subtotal (`discountAmount <= subtotal`).
  - Line total and net document total will never evaluate to a negative value.

---

## 4. Deterministic Totals Calculation Formula
Document totals are calculated deterministically by `SaleCalculationService`:

1. **Line Subtotal:**
   $$\text{lineSubtotal} = \text{round}(\text{quantity} \times \text{unitPrice})$$

2. **Line Discount Amount:**
   $$\text{lineDiscount} = \text{applyDiscount}(\text{lineSubtotal}, \text{discountType}, \text{discountValue})$$

3. **Line Net Subtotal:**
   $$\text{lineTotal} = \text{lineSubtotal} - \text{lineDiscount}$$

4. **Document Subtotal:**
   $$\text{subtotal} = \sum \text{lineSubtotal}$$

5. **Document Item Discount Total:**
   $$\text{itemDiscountTotal} = \sum \text{lineDiscount}$$

6. **Document Level Discount:**
   $$\text{afterItems} = \text{subtotal} - \text{itemDiscountTotal}$$
   $$\text{saleDiscount} = \text{applyDiscount}(\text{afterItems}, \text{saleDiscountType}, \text{saleDiscountValue})$$

7. **Document Tax Amount:**
   $$\text{net} = \text{afterItems} - \text{saleDiscount}$$
   $$\text{tax} = \text{round}\left(\frac{\text{net} \times \text{taxRate}}{100}\right)$$

8. **Grand Total & Remaining:**
   $$\text{grandTotal} = \text{net} + \text{tax}$$
   $$\text{remainingAmount} = \max(0, \text{grandTotal} - \text{paidAmount})$$

---

## 5. Posted Snapshot Immutability
- All pricing fields (`unitPrice`, `baseUnitPrice`, `discountAmount`, `taxAmount`, `subtotal`, `total`) are persisted as immutable snapshot columns in `sales` and `sale_items` tables upon creation/posting.
- Subsequent changes to product catalog prices, customer price lists, or tax configuration will **never** alter historical sales documents or ledger posting records.

---

## 6. Test Suite & Verification Matrix
Verification is enforced via `test/modules/sales/sales_pricing_totals_test.dart` covering:
1. Normal price calculation without discount.
2. Zero discount handling.
3. Percentage discount calculation (e.g. 15%).
4. Fixed amount discount calculation.
5. 100% discount producing zero net total.
6. Invalid discount validation rejection (>100% or <0%).
7. Fractional quantities & fractional prices with exact 2-decimal rounding.
8. Multiple lines & duplicate products aggregation.
9. Combined line-level and document-level discounts.
10. Tax calculation on post-discount net base.
11. Rounding and non-negative clamping guarantees.
12. Posted historical snapshot immutability.
