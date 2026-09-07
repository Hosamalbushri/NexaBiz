# PACKAGE_GLOBAL_GA02_DATA_OWNERSHIP.md — Global Data Ownership & Source of Truth Audit

## Executive Summary
This document establishes the canonical data ownership map for the NexaBiz ERP system. Every business fact (journal balances, stock quantities, valuation layers, document totals, cash balances, sync state) is assigned an absolute, authoritative owner module. Duplicate calculations across UI, providers, or reports are prohibited.

---

## 1. Single Authoritative Data Ownership Map

```
┌───────────────────────────────┬────────────────────────────────────────────────────────────┐
│ Domain / Business Fact        │ Authoritative Source of Truth Owner                        │
├───────────────────────────────┼────────────────────────────────────────────────────────────┤
│ General Ledger & Journals     │ Accounting (`lib/modules/accounting`)                      │
│ Posted Account Balances       │ Accounting Ledger (`journals`, `journal_entries` DB)      │
│ Currency Rates & FX           │ Accounting FX Engine (`company_accounting_config`)          │
├───────────────────────────────┼────────────────────────────────────────────────────────────┤
│ Stock Quantities & Layers     │ Inventory (`lib/modules/inventory`)                        │
│ Stock Valuation & COGS Cost   │ Inventory Cost Engine (`inventory_cost_layers` DB)         │
│ Item Master & Warehouses      │ Inventory Domain (`products`, `warehouses` DB)             │
├───────────────────────────────┼────────────────────────────────────────────────────────────┤
│ Sales Documents & Totals      │ Sales (`lib/modules/sales`)                                │
│ Customer Master & Balances    │ Customers (`lib/modules/customers`)                        │
│ Payment & Settlement Events   │ Receipts & Payments (`lib/modules/receipts_payments`)     │
│ Cash Drawer State & Balances  │ Cash Registers (`lib/modules/cash_registers`)              │
├───────────────────────────────┼────────────────────────────────────────────────────────────┤
│ Reporting & Analytics         │ Read-Only Queries (`lib/modules/reports` Query Adapters)   │
│ Sync Transport & Outbox State │ Sync Engine (`lib/modules/sync` Outbox Engine)             │
└───────────────────────────────┴────────────────────────────────────────────────────────────┘
```

---

## 2. Audit of Financial & Inventory Calculations

### 2.1 Customer Balance
- **Authoritative Owner**: `CustomersDatabase` & `CustomerAccountLinkPort`.
- **Enforcement**: UI screens query `CustomerRepository` which computes balances strictly from settled invoices and payments in the subledger. UI components never accumulate balance state locally.

### 2.2 Inventory Quantity & Valuation
- **Authoritative Owner**: `InventoryDatabase` (`stock_movement_lines`, `inventory_cost_layers`).
- **Enforcement**: Inventory quantity is computed dynamically from posted stock ledger movements. Cost valuation relies on `InventoryCostCalculator` enforcing FIFO or Weighted Average Cost algorithms.

### 2.3 COGS & Profit Calculation
- **Authoritative Owner**: `PostingEngineImpl` in `lib/modules/inventory/stock_movements/data/services/posting_engine_impl.dart`.
- **Enforcement**: COGS is derived from actual inventory cost consumption layers (`inventory_cost_consumptions`) at the exact moment of posting. Sales documents consume this calculated COGS during journal generation.

### 2.4 Cash Register Balance
- **Authoritative Owner**: `CashRegistersDatabase`.
- **Enforcement**: Cash register balances reflect real opening balances plus posted cash receipts/payments minus drawer transfers.

---

## 3. Anti-Patterns Search & Elimination Findings

1. **UI as Source of Truth**:
   - *Audit Result*: No instances found where UI widgets mutate or store authoritative business state. All forms dispatch commands to use cases.
2. **Provider as Source of Truth**:
   - *Audit Result*: Riverpod providers act exclusively as reactive adapters bridging UI to repositories. Stored state is invalidated or updated upon repository events.
3. **Report Creating Financial Truth**:
   - *Audit Result*: Reports use read-only subledger adapters (`InventorySubledgerQueryAdapter`, `JournalQueryAdapter`) and execute aggregate queries without writing back to database tables.

---

## 4. Verification & Consistency Matrix

| Transaction Type | Authoritative Source Result | Source Module | Reports View | Sync Queue Payload |
|---|---|---|---|---|
| Sales Invoice | Revenue Posted & Stock Subtracted | `sales` | Matches Sales Journal | `sales_invoice` entity |
| Inventory Receipt | Cost Layers Created & Stock Added | `inventory` | Matches Inventory Ledger | `stock_receipt` entity |
| Payment Voucher | Allocation Recorded & Balance Adjusted | `receipts_payments` | Matches Cash Ledger | `payment_voucher` entity |
| Inventory Return | Reversal Posting & Stock Returned | `inventory` | Matches Reversal Journal | `inventory_reversal` entity |

**GA-02 Gate Status**: **PASS**
