# SA-09 — Sales Financial Calculation Integrity

## Overview
This document specifies the domain-level standards and deterministic invariants governing all financial calculations in the Sales module. It establishes strict rules for subtotals, item and header discounts, tax calculations, grand totals, payment status derivation, outstanding receivables, and exact accounting journal entry correspondence using integer cents-based arithmetic (`SaleMoney`).

---

## 1. Domain Financial Invariants
For every sale invoice (draft or posted), the following mathematical invariants are strictly enforced:

1. **Subtotal Invariant:**
   $$\text{subtotal} = \sum_{i=1}^{N} \text{round}(\text{quantity}_i \times \text{unitPrice}_i)$$
2. **Line Net Invariant:**
   $$\text{lineTotal}_i = \text{max}(0, \text{lineSubtotal}_i - \text{lineDiscountAmount}_i)$$
3. **Item Discount Total Invariant:**
   $$\text{itemDiscountTotal} = \sum_{i=1}^{N} \text{lineDiscountAmount}_i$$
4. **Header Discount Invariant:**
   Header/Document discounts are calculated strictly on the net amount remaining after item discounts:
   $$\text{afterItems} = \text{max}(0, \text{subtotal} - \text{itemDiscountTotal})$$
   $$\text{saleDiscount} = \text{applyDiscount}(\text{afterItems}, \text{discountType}, \text{discountValue})$$
5. **Net Taxable Amount Invariant:**
   $$\text{netTaxableAmount} = \text{max}(0, \text{afterItems} - \text{saleDiscount})$$
6. **Tax Invariant:**
   $$\text{taxAmount} = \text{round}(\text{netTaxableAmount} \times \frac{\text{taxRatePercent}}{100})$$
7. **Grand Total Invariant:**
   $$\text{grandTotal} = \text{netTaxableAmount} + \text{taxAmount}$$
8. **Settlement Invariant:**
   $$\text{paidAmount} + \text{remainingAmount} = \text{grandTotal}$$

---

## 2. Multi-Tier Discount Calculation Rules
- **Line-Level Discounts:** Computed on individual item line subtotals using percentage or fixed amount.
- **Document-Level Discounts:** Applied to the net amount after line discounts to prevent double-discounting.
- **Non-Negative Clamping:** Discounts are strictly clamped so line totals and document net amounts can never drop below zero ($0.00$).

---

## 3. Tax Calculation Standard
- Tax is calculated on the net taxable amount after all item and header discounts have been deducted.
- Rounding uses standard half-up rounding to 2 decimal places using integer cents representation (`SaleMoney.round`).

---

## 4. Integer Cents Arithmetic (`SaleMoney`)
- Floating-point calculations can introduce binary rounding drift (e.g. `0.1 + 0.2 = 0.30000000000000004`).
- All monetary operations inside `SaleCalculationService` convert values to integer cents (`toCents`), perform exact integer arithmetic, and convert back to 2-decimal rounded double representation (`fromCents`), eliminating rounding drift.

---

## 5. Currency & Inventory Valuation Separation
- Sales financial totals are denominated in the transaction `currencyCode` (e.g. `SAR`).
- Inventory cost layer calculations (COGS) are denominated in the company valuation currency (e.g. `YER`) and tracked independently. Sales total calculations never mix document billing prices with inventory valuation unit costs.

---

## 6. Accounting Journal Entry Correspondence
- Journal entry drafts created by `AccountingEntryBuilder` strictly match the calculated totals:
  - `DEBIT Cash / Customer Receivable`: Equals `grandTotal`.
  - `CREDIT Sales Revenue`: Equals gross revenue before discount or net revenue.
  - `DEBIT Sales Discount`: Equals total discount amount (when configured).
  - `CREDIT Tax Payable`: Equals `taxAmount`.
  - $\sum \text{Debits} = \sum \text{Credits}$ to the exact cent.

---

## 7. Verification Matrix
Verified via `test/modules/sales/sales_financial_calculation_test.dart` covering:
1. Subtotal invariant across single and multi-item sales.
2. Item & document discount aggregation without double-discounting.
3. Tax calculation on post-discount net amount.
4. Grand total invariant ($\text{grandTotal} = \text{subtotal} - \text{discounts} + \text{tax}$).
5. Settlement invariant ($\text{paid} + \text{remaining} = \text{total}$).
6. Immunity to floating-point rounding drift via `SaleMoney`.
7. Perfect journal entry debit/credit balance and accounting correspondence.
