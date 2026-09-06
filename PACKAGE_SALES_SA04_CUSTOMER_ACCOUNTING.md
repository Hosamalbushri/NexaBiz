# SA-04 — Customer Receivables & Accounting Integration

## Overview
This document specifies the integration architecture between the Sales module, Customer management, and the Accounting ledger core in the NexaBiz ERP system.

---

## 1. Customer Identification & Validation (Credit Sales)
For credit sales (`SaleSettlementType.credit`):
- `customerAccountId` must be explicitly specified and validated.
- `SaleValidator` ensures:
  - Customer exists and is active.
  - Customer belongs to the current tenant (`companyId`).
  - Required receivable account (`customerAccountId`) exists in the chart of accounts and belongs to the company.
- Cross-company customer or account references are strictly blocked.

---

## 2. Cash Sale Integration
For cash sales (`SaleSettlementType.cash`):
- Uses the explicitly selected Cash Register / payment account (`cashAccountId`).
- **No Parallel Balances:** Sales does **NOT** maintain a separate internal cash balance inside the Sales module. Cash register balances are governed strictly by the Treasury and Accounting ledgers.

---

## 3. Credit Sale Journal Entries
Conceptually posted as:

- **DEBIT:** Customer Receivable (`customerAccountId` or `AccountRole.receivable`)
- **DEBIT:** Sales Discount (`AccountRole.discount` contra-revenue account, if applicable)
- **CREDIT:** Tax Payable / Output VAT (`AccountRole.tax`, if applicable)
- **CREDIT:** Sales Revenue (`AccountRole.revenue` gross revenue)

---

## 4. COGS & Inventory Costing Integration
Inventory cost layer consumption is governed strictly by the Inventory module (`PostingCoordinatorPort` / `CostingEngine`):
- **DEBIT:** Cost of Goods Sold (`AccountRole.cogs`)
- **CREDIT:** Inventory Asset (`AccountRole.inventory`)
- Sales **NEVER** calculates inventory unit cost or total cost independently. The consumed layer value calculated by the inventory FIFO costing engine is passed directly to the accounting journal builder.

---

## 5. Tax & Discount Accounting Treatment
- **Discounts:** Handled via the accounting mapping resolver (`AccountRole.discount`). If a discount account is configured, the discount amount is debited to the discount account rather than net-reducing gross revenue line items implicitly.
- **Taxes:** Handled via `AccountRole.tax` (Tax Payable / Output VAT). Tax is credited to the liability account and separated from Sales Revenue, satisfying accounting reporting standards.

---

## 6. Single Source of Financial Truth (Customer Balances)
- Customer outstanding balances are derived dynamically from authoritative journal entry postings in the general ledger.
- The Sales module does not maintain an independent manually mutated customer balance column.

---

## 7. Journal Entry Boundary
- Journal entry creation and posting are orchestrated through the central posting boundary (`DocumentPostingOrchestrator` & `AccountingEntryBuilder`).
- Sales UI screens and handlers never create or modify journal entries directly.

---

## 8. Verification Matrix
Verified via `test/modules/sales/sales_accounting_integration_test.dart` covering:
1. Cash sale journal entry generation (DEBIT Cash, CREDIT Revenue).
2. Credit sale journal entry generation (DEBIT Customer Receivable, CREDIT Revenue).
3. Discount accounting treatment (DEBIT Sales Discount).
4. Tax accounting treatment (CREDIT Tax Payable separated from Revenue).
5. COGS journal entry generation (DEBIT COGS, CREDIT Inventory Asset using Inventory cost layers).
6. Customer balance derivation from authoritative financial transactions.
7. Multi-company tenant isolation (rejecting cross-company assignments).
8. Atomic orchestration & posting rollback on side-effect failures.
