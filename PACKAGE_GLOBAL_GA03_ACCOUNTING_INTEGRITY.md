# PACKAGE_GLOBAL_GA03_ACCOUNTING_INTEGRITY.md — Global Accounting Integrity Audit

## Executive Summary
This document presents the system-wide accounting integrity audit for NexaBiz ERP. It verifies strict compliance with core financial accounting principles: double-entry balance ($\sum \text{Debit} = \sum \text{Credit}$), multi-currency historical rate preservation, atomic journal posting, fiscal period closing guards, and unpost reversal consistency across all commercial modules.

---

## 1. Accounting Invariant Verification

Every financial transaction posted within NexaBiz MUST satisfy the following invariants:

1. **Double-Entry Equilibrium**: Total Debit amount EQUALS Total Credit amount ($\sum \text{Debit} - \sum \text{Credit} = 0.0000$).
2. **Company Isolation**: All line items inherit the exact `company_id` of the transaction header. Cross-company posting within a single journal is rejected.
3. **Fiscal Period Validation**: Posting is blocked if `PeriodValidatorPort.assertEntryAllowed(documentDate)` throws a closed period exception.
4. **Account Validity**: Debit and Credit accounts must be active, leaf accounts existing in `chart_of_accounts`.
5. **Historical FX Rates**: Multi-currency entries persist document FX rates at time of entry. Historical journals are NEVER revalued using current exchange rates.

---

## 2. End-to-End Financial Flow Tracing

### 2.1 Sales Transaction Flow
```
[Sales Invoice Created]
        │
        ▼ (Posting Engine)
  ┌───────────────────────────────────────────────────────────┐
  │ DR: Customer Accounts Receivable / Cash Register           │
  │ CR: Sales Revenue                                         │
  ├───────────────────────────────────────────────────────────┤
  │ DR: Cost of Goods Sold (COGS)                             │
  │ CR: Inventory Asset Account                               │
  └───────────────────────────────────────────────────────────┘
```
- **Audit Findings**: Verified in `atomic_inventory_accounting_posting_test.dart`. Inventory cost is calculated dynamically using cost layers, guaranteeing that COGS matches stock valuation.

### 2.2 Payment Voucher Flow
```
[Payment Voucher Received]
        │
        ▼ (RP Workflow Service)
  ┌───────────────────────────────────────────────────────────┐
  │ DR: Cash Register Account / Bank Account                  │
  │ CR: Customer Accounts Receivable                          │
  └───────────────────────────────────────────────────────────┘
```
- **Audit Findings**: Directional typing (`receipt` vs `payment`) prevents inverted credit/debit assignments. Settled customer balance decreases immediately.

### 2.3 Inventory Receipt Flow
```
[Stock Receipt Posted]
        │
        ▼ (Posting Coordinator)
  ┌───────────────────────────────────────────────────────────┐
  │ DR: Inventory Asset Account                               │
  │ CR: Goods Received Not Invoiced (GRNI) / Payable Account   │
  └───────────────────────────────────────────────────────────┘
```
- **Audit Findings**: Enforces non-zero unit cost for stock receipts. Creates cost valuation layers in `inventory_cost_layers`.

### 2.4 Inventory Return & Reversal Flow
```
[Document Unposted / Reversal Executed]
        │
        ▼ (Reversal Engine)
  ┌───────────────────────────────────────────────────────────┐
  │ Original Journal Entry set to status = 'reversed'        │
  │ Reversal Journal Entry created with inverted DR/CR values  │
  └───────────────────────────────────────────────────────────┘
```
- **Audit Findings**: Reversal preserves original transaction timestamps and historical unit costs. Stock layers consumed during outbound transactions are restored idempotently.

---

## 3. Multi-Currency Accounting Audit

- **Document Currency vs Accounting Base Currency**: Transactions record both `documentCurrencyAmount` and `baseCurrencyAmount` alongside the exact `exchangeRate`.
- **Historical Protection**: Historical ledgers use the rate persisted in the `journals` record. Changing company base currency exchange rates does not alter historical accounting balances.

---

## 4. Required Business Tests & Assertions

| Business Invariant Test | Implementation Verification Path | Result |
|---|---|---|
| Sale Posts Exactly Once | `test/sales_final_test.dart` | Passed |
| Payment Posts Exactly Once | `test/receipts_payments_phase6_test.dart` | Passed |
| Duplicate Retry Creates No Economic Event | `PostingCoordinatorImpl` Idempotency Guard | Passed |
| Return Reverses Correct Economic Values | `test/accounting_reversal_historical_preservation_test.dart` | Passed |
| Debit Equals Credit | `test/accounting_balance_invariant_test.dart` | Passed |
| Customer Outstanding Balance | `CustomerAccountLinkPort` Tests | Passed |
| Inventory Value Equals Stock Layers | `InventoryCostCalculator` Tests | Passed |
| COGS Agrees with Inventory Asset | `PostingEngineImpl` Inter-Module Test | Passed |

**GA-03 Gate Status**: **PASS**
