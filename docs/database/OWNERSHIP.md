# NEXABIZ ERP — MODULE OWNERSHIP & AUTHORITY MATRIX (OWNERSHIP.md)

## 1. Governance Principles

1. **Single Authoritative Domain Owner**: Every database entity and business state concept in NexaBiz is owned by exactly **ONE** domain module.
2. **Forbidden Cross-Module Writes**: Direct SQL or repository table mutation across domain boundaries is strictly prohibited. Cross-domain interactions MUST execute through formal Domain Ports and Application Use Cases.
3. **Forensic Authority Distinction**: The matrix explicitly distinguishes authoritative source-of-truth ledgers from derived, rebuildable read projections.

---

## 2. Canonical Authority Matrix

| Domain Concept | Owning Module | Authoritative State Table | Derived / Rebuildable Read Projection | Approved Writers | Forbidden Writers |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Product Master** | `inventory` | `products` | Product Catalog Views | `ProductRepository` | Sales, Purchases, Accounting |
| **Physical Stock Ledger History** | `inventory` | `stock_movement_ledgers` | N/A (Authoritative Source of Truth) | `PostingEngine` | Sales, Purchases, UI, Direct SQL |
| **Stock Balance Projection** | `inventory` | `stock_movement_ledgers` | `product_warehouse_stocks` | `PostingEngine` (Rebuilt from ledger) | Sales, UI, Direct SQL |
| **WAC Average Cost** | `inventory` | `stock_movement_ledgers` | `products.avg_cost` (Derived/Rebuildable) | `CostLayerService` | Sales, Accounting, UI |
| **FIFO Cost Layers** | `inventory` | `inventory_cost_layers` | Active Cost Layer State | `CostLayerService` | Sales, Accounting, UI |
| **COGS Traceability** | `inventory` | `inventory_cost_consumptions` | COGS Traceability Reports | `CostLayerService` | Sales, Treasury |
| **Warehouse Master** | `inventory` | `warehouses` | Warehouse Selection Lists | `WarehouseRepository` | Sales, Accounting |
| **Customer Master** | `customers` | `customers` | Customer Directory | `CustomerRepository` | Sales, Treasury |
| **Supplier Master** | `purchases` | `suppliers` | Supplier Directory | `SupplierRepository` | Purchases, Treasury |
| **Chart of Accounts** | `accounting` | `accounts` | COA Tree Views | `AccountRepository` | Inventory, Sales, Treasury |
| **General Ledger (GL)** | `accounting` | `journal_entries`, `journal_lines` | Trial Balance, Ledger Reports | `JournalPostingService` | Sales, Inventory, Treasury |
| **Customer AR Balance** | `accounting` | `journal_lines` (AR GL Account) | Customer Statement View | `JournalPostingService` | Customer Repo, Sales |
| **Supplier AP Balance** | `accounting` | `journal_lines` (AP GL Account) | Supplier Statement View | `JournalPostingService` | Supplier Repo, Purchases |
| **Cash Drawer Register** | `cash_registers` | `cash_registers` | Active Drawer State | `CashRegisterRepository` | Accounting, Sales |
| **Voucher Sequences** | `accounting` | `voucher_books` | Next Voucher Code Generator | `VoucherSequenceService` | Sales, Inventory, Treasury |
| **Global Currencies** | `accounting` | `currencies` | Global Currency Pickers | `CurrencyRepository` | Inventory, Sales |
| **Exchange Rates** | `accounting` | `currency_rates`, `currency_rate_history` | FX Conversion Engine | `CurrencyRepository` | Inventory, Sales |
| **Sales Document** | `sales` | `sales`, `sale_items`, `sale_payments` | Sales Order Lists | `SaleRepository` | Inventory, Accounting |
| **Purchase Document** | `purchases` | `purchases`, `purchase_items`, `purchase_payments` | Purchase Order Lists | `PurchaseRepository` | Inventory, Accounting |
| **Treasury Vouchers** | `receipts_payments` | `financial_transactions` | Cash Book / Voucher Views | `FinancialTransactionRepository` | Accounting, Sales |
| **Fiscal Calendar** | `accounting` | `fiscal_years`, `accounting_periods` | Period Lock Indicators | `FiscalPeriodService` | Sales, Inventory, Treasury |

---

## 3. Forensic Authority Verification Findings

### Forensic Question 1
> If `product_warehouse_stocks` is deleted, can authoritative stock state be reconstructed?
- **ANSWER**: **YES.** `product_warehouse_stocks` is a derived read projection. Authoritative stock balance per product per warehouse is reconstructed by calculating the net quantity sum of all valid posted movements in `stock_movement_ledgers`.

### Forensic Question 2
> If `stock_movement_ledgers` is deleted, can authoritative stock history be reconstructed?
- **ANSWER**: **NO.** `stock_movement_ledgers` is the immutable, authoritative source of truth for physical stock movement history. If deleted, historical stock movements cannot be recovered.
