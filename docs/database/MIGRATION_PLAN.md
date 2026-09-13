# NEXABIZ ERP — CANONICAL MIGRATION PLAN (MIGRATION_PLAN.md)

## 1. Executive Summary & Design-Only Scope

This document specifies the migration strategy for consolidating the 5 legacy fragmented SQLite databases (`sales_master.sqlite`, `inventory_products.sqlite`, `receipts_payments.sqlite`, `accounting_accounts.sqlite`, `customers_master.sqlite`) into a single canonical database (`nexabiz.sqlite`).

```text
STRICT READ-ONLY / DESIGN-ONLY MODE
This is a DESIGN-ONLY specification.
NO SQL migrations were executed.
NO schema was modified.
NO tables were renamed or deleted.
NO production data was modified.
```

---

## 2. Migration Architecture & Strategy D Selection

Based on forensic audit findings (`docs/architecture/phase-02-canonical-database-forensic-audit.md`), NexaBiz adopts **Strategy D: Adapter Compatibility Layer & Incremental Domain Migration**.

---

## 3. Current vs. Target Structure Matrix

| Current Structure (Table & Database) | Current Business Meaning | Target Canonical Structure | Decision Dependency | Status |
| :--- | :--- | :--- | :--- | :---: |
| `canonical_db_metadata` (`nexabiz`) | Schema Metadata | `canonical_db_metadata` | Standard System Metadata | APPROVED |
| `users` (`nexabiz`) | User Directory | `users` | Identity subject to D-12 | APPROVED |
| `companies` (`nexabiz`) | Tenant Root | `companies` | Identity subject to D-12 | APPROVED |
| `company_memberships` (`nexabiz`) | User Access | `company_memberships` | Identity subject to D-12 | APPROVED |
| `currencies` (`accounting`) | Global Currencies | `currencies` | Global Reference Scope | APPROVED |
| `product_categories` (`inventory`) | Product Categories | `product_categories` | Identity subject to D-12 | APPROVED |
| `warehouses` (`inventory`) | Storage Locations | `warehouses` | Identity subject to D-12 | APPROVED |
| `accounts` (`accounting`) | Chart of Accounts | `accounts` | Identity subject to D-12 | APPROVED |
| `products` (`inventory`) | Item Catalog | `products` | Identity subject to D-12 | APPROVED |
| `customers` (`customers`) | Customer Directory | `customers` | Identity subject to D-12 | APPROVED |
| `suppliers` (`nexabiz`) | Vendor Directory | `suppliers` | Identity subject to D-12 | APPROVED |
| `cash_registers` (`accounting`) | Cash Drawers | `cash_registers` | Identity subject to D-12 | APPROVED |
| `voucher_books` (`accounting`) | Document Sequences | `voucher_books` | Identity subject to D-12 | APPROVED |
| `stock_receipts` (`inventory`) | Inbound Receipts | `stock_receipts` | Identity subject to D-12 | APPROVED |
| `stock_issues` (`inventory`) | Outbound Issues | `stock_issues` | Identity subject to D-12 | APPROVED |
| `stock_returns` (`inventory`) | Returns Header | `stock_returns` | Identity subject to D-12 | APPROVED |
| `stock_transfers` (`inventory`) | Transfers Header | `stock_transfers` | Identity subject to D-12 | APPROVED |
| `stock_movement_lines` (`inventory`) | Detail Lines | `stock_movement_lines` | Identity subject to D-12 | APPROVED |
| `stock_movement_ledgers` (`inventory`) | Physical Stock Ledger | `stock_movement_ledgers` | Identity subject to D-12 | APPROVED |
| `inventory_cost_layers` (`inventory`) | FIFO Cost Layers | `inventory_cost_layers` | Identity subject to D-12 | APPROVED |
| `inventory_cost_consumptions` (`inventory`) | FIFO Consumptions | `inventory_cost_consumptions` | Identity subject to D-12 | APPROVED |
| `product_warehouse_stocks` (`inventory`) | Derived Stock Projection | `product_warehouse_stocks` | Rebuildable projection | APPROVED |
| `warehouse_accounting_bindings` (`inventory`) | GL Integration | `warehouse_accounting_bindings` | Identity subject to D-12 | APPROVED |
| `inventory_audit_trail` (`inventory`) | Stock Audit Log | `inventory_audit_trail` | Identity subject to D-12 | APPROVED |
| `sales` (`sales`) | Sale Invoices | `sales` | Identity subject to D-12 | APPROVED |
| `sale_items` (`sales`) | Sale Lines | `sale_items` | Identity subject to D-12 | APPROVED |
| `sale_payments` (`sales`) | Sale Settlements | `sale_payments` | Identity subject to D-12 | APPROVED |
| `purchases` (`nexabiz`) | Purchase Invoices | `purchases` | Identity subject to D-12 | APPROVED |
| `purchase_items` (`nexabiz`) | Purchase Lines | `purchase_items` | Identity subject to D-12 | APPROVED |
| `purchase_payments` (`nexabiz`) | Purchase Settlements | `purchase_payments` | Identity subject to D-12 | APPROVED |
| `financial_transactions` (`receipts_payments`) | Cash Vouchers | `financial_transactions` | Identity subject to D-12 | APPROVED |
| `fiscal_years` (`accounting`) | Fiscal Calendar | `fiscal_years` | Identity subject to D-12 | APPROVED |
| `accounting_periods` (`accounting`) | Fiscal Periods | `accounting_periods` | Identity subject to D-12 | APPROVED |
| `period_closing_records` (`accounting`) | Period Closing Logs | `period_closing_records` | Identity subject to D-12 | APPROVED |
| `journal_entries` (`accounting`) | GL Entry Headers | `journal_entries` | Identity subject to D-12 | APPROVED |
| `journal_lines` (`accounting`) | GL Entry Lines | `journal_lines` | Identity subject to D-12 | APPROVED |
| `currency_rates` (`accounting`) | FX Rates | `currency_rates` | Identity subject to D-12 | APPROVED |
| `currency_rate_history` (`accounting`) | Historical FX Rates | `currency_rate_history` | Tenant scope added | APPROVED |
| `AccountCurrencyBalances` | Unregistered Class | Deprecate class code | Code cleanup | APPROVED |
| `sync_operations` / `sync_queue` | Sync Outbox Storage | Physical Outbox Storage | Dependent on D-11 | **UNRESOLVED** |
| Generic Non-Inventory Void / Correction | Financial Reversals | Generic Void Schema | Dependent on D-14 | **UNRESOLVED** |
| Identity Hierarchy & Foreign Keys | PK / FK Schemes | Physical Key Scheme (UUID v7) | Resolved by D-12 (`D12_IDENTITY_DECISION.md`) | **APPROVED** |

---

## 4. Migration Validation Gates & Data Preservation Requirements

1. **Zero Data Loss Guarantee**: All historical transactions MUST be migrated intact.
2. **Reconciliation Validation Gate**:
   - Total GL Trial Balance (`SUM(base_debit) == SUM(base_credit)`).
   - Total Stock Ledger Quantity per product == Derived `product_warehouse_stocks.on_hand_qty`.
   - Total FIFO layer remaining quantity == Total physical stock ledger quantity.
3. **Rollback Strategy**: If any validation gate fails during migration, the system aborts transaction and reverts active connection back to legacy database files without corrupting existing data.
