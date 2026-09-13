# NEXABIZ ERP — ENTITY SPECIFICATION (ENTITIES.md)

## 1. Overview & Identity Governance (Decision D-12)

This specification details all 39 domain entities of NexaBiz ERP. 

### D-12 Identity Standard
```text
RESOLVED AND FROZEN UNDER DECISION D-12 (D12_IDENTITY_DECISION.md)
All 39 canonical entities use UUID v7 (RFC 9562) as their sole technical identity (except canonical_db_metadata key and ISO currency code).
Local integer autoincrement primary keys and integer foreign keys are strictly prohibited.
Multi-tenant integrity is enforced via Composite Tenant-Aware Foreign Keys (company_id, target_id).
```

---

## 2. System Domain Entities

### 2.1 CanonicalDbMetadata (`canonical_db_metadata`)
- **Business Purpose**: Schema migration metadata tracking.
- **Owner Module**: Core / System (`lib/core/database/canonical_db_metadata_table.dart`)
- **Tenant Scope**: SYSTEM
- **Identity**: Distinguishable metadata key identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `key`, `updated_at`.
- **Optional Attributes**: `value`.
- **Delete Semantics**: Persistent system record.

### 2.2 User (`users`)
- **Business Purpose**: Directory of application users.
- **Owner Module**: Core Auth
- **Tenant Scope**: SYSTEM
- **Identity**: Distinguishable user identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `username`, `email`, `password_hash`, `full_name`, `status`, `created_at`, `updated_at`.
- **Optional Attributes**: `phone`, `avatar_url`, `deleted_at`.
- **Delete Semantics**: Soft deletion via status / `deleted_at`.

### 2.3 Company (`companies`)
- **Business Purpose**: Tenant organization root entity.
- **Owner Module**: Core Tenancy
- **Tenant Scope**: COMPANY (Tenant Root)
- **Identity**: Distinguishable company tenant identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `name`, `code`, `status`, `currency_code`, `created_at`, `updated_at`.
- **Optional Attributes**: `tax_number`, `logo_url`, `address`, `phone`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Deletion prohibited if active tenant records exist.

### 2.4 CompanyMembership (`company_memberships`)
- **Business Purpose**: Maps user access privileges within a specific company.
- **Owner Module**: Core Security
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable membership identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `user_id`, `role`, `status`, `created_at`, `updated_at`.
- **Optional Attributes**: `permissions_override`, `deleted_at`.
- **Delete Semantics**: Membership revoked or soft deleted.

---

## 3. Master Data Domain Entities

### 3.1 Currency (`currencies`)
- **Business Purpose**: Master catalog of standard ISO 4217 currency definitions.
- **Owner Module**: Accounting
- **Tenant Scope**: GLOBAL REFERENCE (Shared catalog across companies)
- **Identity**: Distinguishable currency identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `code` (ISO 4217), `name_ar`, `name_en`, `symbol`, `decimal_digits`, `is_default`, `created_at`.
- **Optional Attributes**: None.
- **Delete Semantics**: Persistent master reference data.

### 3.2 ProductCategory (`product_categories`)
- **Business Purpose**: Hierarchical product classification within a company tenant.
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable category identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `created_at`, `updated_at`.
- **Optional Attributes**: `parent_category_id`, `description`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Hard delete blocked if assigned to active products.

### 3.3 Warehouse (`warehouses`)
- **Business Purpose**: Inventory storage location within a company.
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable warehouse identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `is_active`, `created_at`, `updated_at`.
- **Optional Attributes**: `address`, `phone`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Deletion blocked if active stock balance exists.

### 3.4 Product (`products`)
- **Business Purpose**: Master item catalog entity holding SKU, costing method (`WAC`/`FIFO`), and cost projections.
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable product master identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `sku`, `name`, `costing_method` (`WAC`/`FIFO`), `unit`, `created_at`, `updated_at`.
- **Optional Attributes**: `barcode`, `category_id`, `sale_price`, `purchase_cost`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Physical removal blocked if posted stock movements exist.

### 3.5 Customer (`customers`)
- **Business Purpose**: Commercial customer record.
- **Owner Module**: Customers
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable customer identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `created_at`, `updated_at`.
- **Optional Attributes**: `phone`, `email`, `tax_number`, `address`, `account_id`, `credit_limit`, `deleted_at`.
- **Delete Semantics**: Soft deletion.

### 3.6 Supplier (`suppliers`)
- **Business Purpose**: Commercial vendor record.
- **Owner Module**: Purchases
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable supplier identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `created_at`, `updated_at`.
- **Optional Attributes**: `phone`, `email`, `tax_number`, `address`, `account_id`, `deleted_at`.
- **Delete Semantics**: Soft deletion.

### 3.7 Account (`accounts`)
- **Business Purpose**: Chart of Accounts (COA) master account.
- **Owner Module**: Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable account identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `type` (`asset`, `liability`, `equity`, `revenue`, `expense`), `is_active`, `created_at`, `updated_at`.
- **Optional Attributes**: `parent_account_id`, `currency_code`, `description`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Deletion blocked if GL journal entries exist.

### 3.8 CashRegister (`cash_registers`)
- **Business Purpose**: Treasury cash drawer or bank register.
- **Owner Module**: Treasury
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable register identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `name`, `account_id`, `is_active`, `created_at`, `updated_at`.
- **Optional Attributes**: `warehouse_id`, `user_id`, `currency_code`, `deleted_at`.
- **Delete Semantics**: Soft deletion.

### 3.9 VoucherBook (`voucher_books`)
- **Business Purpose**: Document sequence generator book per company and document type.
- **Owner Module**: System / Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable voucher book identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `code`, `name`, `type`, `prefix`, `current_number`, `created_at`, `updated_at`.
- **Optional Attributes**: `suffix`, `padding`, `is_active`, `deleted_at`.
- **Delete Semantics**: Soft deletion. Monotonic increment invariant.

---

## 4. Inventory Domain Entities

### 4.1 StockReceipt (`stock_receipts`)
- **Business Purpose**: Inbound stock document header (`Draft` -> `Posted` -> `Unpost`).
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable document header identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `receipt_number`, `warehouse_id`, `status` (`draft`, `posted`), `receipt_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `supplier_id`, `purchase_id`, `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft child rows deleted as part of draft aggregate lifecycle; posted documents are immutable and must not be physically removed through ordinary editing.

### 4.2 StockIssue (`stock_issues`)
- **Business Purpose**: Outbound stock document header (`Draft` -> `Posted` -> `Unpost`).
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable document header identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `issue_number`, `warehouse_id`, `status` (`draft`, `posted`), `issue_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `customer_id`, `sale_id`, `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable/deletable; posted immutable.

### 4.3 StockReturn (`stock_returns`)
- **Business Purpose**: Commercial inventory return document header. Valued using current product cost at posting time.
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable document header identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `return_number`, `warehouse_id`, `return_type`, `status`, `return_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `original_document_id`, `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable/deletable; posted immutable.

### 4.4 StockTransfer (`stock_transfers`)
- **Business Purpose**: Inter-warehouse transfer header (`Draft` -> `Posted` -> `Unpost`).
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable document header identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `transfer_number`, `source_warehouse_id`, `target_warehouse_id`, `status`, `transfer_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable/deletable; posted immutable.

### 4.5 StockMovementLine (`stock_movement_lines`)
- **Business Purpose**: Detail line item on inventory documents. One document line may produce zero, one, or multiple stock movement ledger effects.
- **Owner Module**: Inventory
- **Tenant Scope**: INHERITED COMPANY (Inherited via parent movement header)
- **Identity**: Distinguishable document line identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `movement_id`, `product_id`, `quantity`, `unit_cost`, `total_cost`, `created_at`.
- **Optional Attributes**: `notes`, `batch_number`, `expiry_date`.
- **Delete Semantics**: Draft lines deleted during draft aggregate edit; posted lines immutable.

### 4.6 StockMovementLedger (`stock_movement_ledgers`)
- **Business Purpose**: Authoritative physical stock ledger recording all POSTED movements.
- **Owner Module**: Inventory (Authoritative Physical Stock History)
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable ledger effect identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `product_id`, `warehouse_id`, `movement_type`, `quantity`, `unit_cost`, `total_cost`, `source_document_type`, `source_document_id`, `movement_date`, `created_at`.
- **Optional Attributes**: `source_line_id`, `batch_number`.
- **Delete Semantics**: Physical removal permitted ONLY as part of atomic document `UNPOST` operation.

### 4.7 InventoryCostLayer (`inventory_cost_layers`)
- **Business Purpose**: Inbound FIFO valuation cost layer tracking `initial_qty` and `remaining_qty`.
- **Owner Module**: Inventory (Authoritative FIFO Valuation State)
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable cost layer identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `product_id`, `warehouse_id`, `initial_qty`, `remaining_qty`, `unit_cost`, `posting_date`, `created_at`.
- **Optional Attributes**: `source_document_id`, `source_line_id`, `is_fully_consumed`.
- **Delete Semantics**: Rebuilt or updated during posting, FIFO consumption, and unposting recalculation.

### 4.8 InventoryCostConsumption (`inventory_cost_consumptions`)
- **Business Purpose**: Audit trail mapping an outbound movement to consumed FIFO cost layers.
- **Owner Module**: Inventory (COGS Traceability Ledger)
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable consumption identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `cost_layer_id`, `outbound_movement_id`, `consumed_qty`, `unit_cost`, `total_cost`, `consumed_at`.
- **Optional Attributes**: `product_id`.
- **Delete Semantics**: Atomically removed during document unposting recalculation.

### 4.9 ProductWarehouseStock (`product_warehouse_stocks`)
- **Business Purpose**: Derived stock balance projection per product per warehouse.
- **Owner Module**: Inventory (Derived Read Projection)
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable projection identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `product_id`, `warehouse_id`, `on_hand_qty`, `reserved_qty`, `updated_at`.
- **Optional Attributes**: `reorder_level`.
- **Delete Semantics**: Derived projection (Rebuilt automatically from `stock_movement_ledgers`).

### 4.10 WarehouseAccountingBinding (`warehouse_accounting_bindings`)
- **Business Purpose**: Maps warehouse to default GL inventory/COGS accounts.
- **Owner Module**: Inventory / Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable binding identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `warehouse_id`, `inventory_account_id`, `cogs_account_id`, `created_at`, `updated_at`.
- **Optional Attributes**: `adjustment_account_id`, `revenue_account_id`.
- **Delete Semantics**: Mutable configuration.

### 4.11 InventoryAuditTrail (`inventory_audit_trail`)
- **Business Purpose**: Append-only log recording inventory posting, unposting, and recalculation events.
- **Owner Module**: Inventory
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable audit identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `action`, `document_type`, `document_id`, `user_id`, `timestamp`.
- **Optional Attributes**: `details_json`.
- **Delete Semantics**: Strictly append-only (No delete).

---

## 5. Commercial Domain Entities (Sales & Purchases)

### 5.1 Sale (`sales`)
- **Business Purpose**: Commercial sale invoice header.
- **Owner Module**: Sales
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable sale document identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `invoice_number`, `customer_id`, `warehouse_id`, `status`, `total_amount`, `currency_code`, `sale_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable; posted immutable.

### 5.2 SaleItem (`sale_items`)
- **Business Purpose**: Commercial sale detail line.
- **Owner Module**: Sales
- **Tenant Scope**: INHERITED COMPANY (Inherited via `sale_id`)
- **Identity**: Distinguishable line identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `sale_id`, `product_id`, `quantity`, `unit_price`, `total_price`, `created_at`.
- **Optional Attributes**: `unit_cost`, `discount_amount`, `tax_amount`.
- **Delete Semantics**: Governed by parent sale lifecycle.

### 5.3 SalePayment (`sale_payments`)
- **Business Purpose**: Payment settlement line associated with a sale invoice.
- **Owner Module**: Sales / Treasury
- **Tenant Scope**: INHERITED COMPANY (Inherited via `sale_id`)
- **Identity**: Distinguishable payment identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `sale_id`, `payment_method`, `amount`, `payment_date`, `created_at`.
- **Optional Attributes**: `cash_register_id`, `reference_number`.
- **Delete Semantics**: Immutable settlement record.

### 5.4 Purchase (`purchases`)
- **Business Purpose**: Commercial purchase invoice header.
- **Owner Module**: Purchases
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable purchase document identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `purchase_number`, `supplier_id`, `warehouse_id`, `status`, `total_amount`, `currency_code`, `purchase_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable; posted immutable.

### 5.5 PurchaseItem (`purchase_items`)
- **Business Purpose**: Commercial purchase detail line.
- **Owner Module**: Purchases
- **Tenant Scope**: INHERITED COMPANY (Inherited via `purchase_id`)
- **Identity**: Distinguishable line identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `purchase_id`, `product_id`, `quantity`, `unit_cost`, `total_cost`, `created_at`.
- **Optional Attributes**: `tax_amount`.
- **Delete Semantics**: Governed by parent purchase lifecycle.

### 5.6 PurchasePayment (`purchase_payments`)
- **Business Purpose**: Payment settlement line associated with a purchase invoice.
- **Owner Module**: Purchases / Treasury
- **Tenant Scope**: INHERITED COMPANY (Inherited via `purchase_id`)
- **Identity**: Distinguishable payment identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `purchase_id`, `payment_method`, `amount`, `payment_date`, `created_at`.
- **Optional Attributes**: `cash_register_id`, `reference_number`.
- **Delete Semantics**: Immutable settlement record.

---

## 6. Treasury Domain Entities

### 6.1 FinancialTransaction (`financial_transactions`)
- **Business Purpose**: Cash receipt, cash payment, or bank voucher header.
- **Owner Module**: Treasury
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable voucher identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `voucher_number`, `voucher_type`, `cash_register_id`, `amount`, `currency_code`, `status`, `transaction_date`, `created_at`, `updated_at`.
- **Optional Attributes**: `party_type`, `party_id`, `counter_account_id`, `notes`, `posted_at`, `deleted_at`.
- **Delete Semantics**: Draft editable; posted immutable.

---

## 7. Accounting Domain Entities

### 7.1 FiscalYear (`fiscal_years`)
- **Business Purpose**: Company fiscal calendar year.
- **Owner Module**: Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable fiscal year identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `year_name`, `start_date`, `end_date`, `is_closed`, `created_at`.
- **Optional Attributes**: `closed_at`, `deleted_at`.
- **Delete Semantics**: Deletion blocked if accounting periods or journal entries exist.

### 7.2 AccountingPeriod (`accounting_periods`)
- **Business Purpose**: Monthly fiscal calendar subdivision.
- **Owner Module**: Accounting
- **Tenant Scope**: INHERITED COMPANY (Inherited via `fiscal_year_id`)
- **Identity**: Distinguishable period identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `fiscal_year_id`, `period_name`, `period_number`, `start_date`, `end_date`, `is_closed`, `created_at`.
- **Optional Attributes**: `closed_at`.
- **Delete Semantics**: Deletion blocked if journal entries exist.

### 7.3 PeriodClosingRecord (`period_closing_records`)
- **Business Purpose**: Audit lock snapshot for closed accounting period.
- **Owner Module**: Accounting
- **Tenant Scope**: INHERITED COMPANY (Inherited via `period_id`)
- **Identity**: Distinguishable closing record identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `period_id`, `closed_by_user_id`, `closed_at`, `summary_hash`.
- **Optional Attributes**: `reopening_notes`.
- **Delete Semantics**: Immutable lock record.

### 7.4 JournalEntry (`journal_entries`)
- **Business Purpose**: Authoritative General Ledger journal header.
- **Owner Module**: Accounting (Sole Financial Authority)
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable journal entry identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `entry_number`, `voucher_type`, `entry_date`, `status` (`posted`, `reversed`), `created_at`, `updated_at`.
- **Optional Attributes**: `source_module`, `source_document_id`, `notes`, `posted_at`, `reversed_at`, `reversal_entry_id`.
- **Delete Semantics**: Physical delete strictly prohibited.

### 7.5 JournalLine (`journal_lines`)
- **Business Purpose**: General Ledger debit or credit detail line. Set-level balance invariant enforced across lines.
- **Owner Module**: Accounting
- **Tenant Scope**: INHERITED COMPANY (Inherited via `entry_id`)
- **Identity**: Distinguishable journal line identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `entry_id`, `account_id`, `debit_amount`, `credit_amount`, `currency_code`, `exchange_rate`, `base_debit`, `base_credit`, `created_at`.
- **Optional Attributes**: `notes`, `party_type`, `party_id`, `cost_center_id`.
- **Delete Semantics**: Physical delete strictly prohibited.

### 7.6 CurrencyRate (`currency_rates`)
- **Business Purpose**: Active foreign exchange rate per company tenant.
- **Owner Module**: Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable currency rate identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `from_currency`, `to_currency`, `rate`, `as_of_date`, `updated_at`.
- **Optional Attributes**: `rate_source`.
- **Delete Semantics**: Active rate updated in-place; history recorded in `currency_rate_history`.

### 7.7 CurrencyRateHistory (`currency_rate_history`)
- **Business Purpose**: Company-scoped historical foreign exchange rate log.
- **Owner Module**: Accounting
- **Tenant Scope**: COMPANY (`company_id`)
- **Identity**: Distinguishable history identity (UUID v7 (RFC 9562) under Decision D-12).
- **Required Attributes**: `company_id`, `currency_code`, `target_currency`, `rate`, `effective_date`, `created_at`.
- **Optional Attributes**: `rate_source`.
- **Delete Semantics**: Append-only (No delete).

### 7.8 AccountCurrencyBalance (`account_currency_balances`)
- **Business Purpose**: Tracks multi-currency sub-balances per account and per currency.
- **Owner Module**: Accounting
- **Tenant Scope**: INHERITED COMPANY (Inherited via parent `Account`)
- **Identity**: Technical Primary Key `id = UUID v7` (RFC 9562) under Decision D-12.
- **Required Attributes**: `company_id`, `account_id`, `currency_code`, `balance`, `base_balance`, `updated_at`.
- **Optional Attributes**: None.
- **Delete Semantics**: Derived sub-balance child entity updated via `JournalPostingService`.

