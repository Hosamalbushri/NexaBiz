# NEXABIZ ERP — TENANCY & MULTI-TENANT SCHEMA SPECIFICATION (TENANCY.md)

## 1. Multi-Tenant Architectural Mandate

NexaBiz ERP operates as a multi-company application. Every company-owned business operation MUST execute inside an authoritative active company context (`TenantContext.activeCompanyId`).

---

## 2. Classification of Tenant Scope

Every domain entity is classified into exactly one of four tenant scope tiers:

### 2.1 SYSTEM Scope
Entities operating above company boundaries for global system administration and authentication.
- **Entities**: `canonical_db_metadata`, `users`.

### 2.2 GLOBAL REFERENCE Scope
Standard master catalog definitions shared across companies.
- **Entities**: `currencies` (Global ISO 4217 currency catalog).

### 2.3 COMPANY Scope
Entities owned directly by a specific tenant company, containing a `company_id` attribute. Every database query on these entities MUST enforce company ownership (`WHERE company_id = activeCompanyId`).
- **Entities**: `companies`, `company_memberships`, `warehouses`, `product_categories`, `products`, `customers`, `suppliers`, `accounts`, `cash_registers`, `voucher_books`, `stock_receipts`, `stock_issues`, `stock_returns`, `stock_transfers`, `stock_movement_ledgers`, `inventory_cost_layers`, `inventory_cost_consumptions`, `product_warehouse_stocks`, `warehouse_accounting_bindings`, `inventory_audit_trail`, `sales`, `purchases`, `financial_transactions`, `fiscal_years`, `journal_entries`, `currency_rates`, `currency_rate_history`.

### 2.4 INHERITED COMPANY Scope
Child line tables and sub-entities that inherit tenant boundaries strictly via their foreign key relationship to a company-scoped parent header.
- **Entities & Inherited Scope Paths**:
  - `sale_items` -> Inherits tenant scope via parent `Sale` (`sale_id` -> `sales.company_id`).
  - `sale_payments` -> Inherits tenant scope via parent `Sale` (`sale_id` -> `sales.company_id`).
  - `purchase_items` -> Inherits tenant scope via parent `Purchase` (`purchase_id` -> `purchases.company_id`).
  - `purchase_payments` -> Inherits tenant scope via parent `Purchase` (`purchase_id` -> `purchases.company_id`).
  - `stock_movement_lines` -> Inherits tenant scope via parent document header (`receipt_id`/`issue_id`/`return_id`/`transfer_id` -> header `company_id`).
  - `inventory_cost_consumptions` -> Inherits tenant scope via `stock_movement_ledgers` / `inventory_cost_layers`.
  - `journal_lines` -> Inherits tenant scope via parent `JournalEntry` (`entry_id` -> `journal_entries.company_id`).
  - `account_currency_balances` -> Inherits tenant scope via parent `Account` (`account_id` -> `accounts.company_id`).
  - `accounting_periods` -> Inherits tenant scope via parent `FiscalYear` (`fiscal_year_id` -> `fiscal_years.company_id`).
  - `period_closing_records` -> Inherits tenant scope via parent `AccountingPeriod` (`period_id` -> `accounting_periods`).

---

## 3. Cross-Company Reference Prevention

The schema enforces strict tenant isolation at both the database engine level and application repository layer:
- **Prohibited Cross-Company Reference**:
  $$\text{Company A Product} \longrightarrow \text{Company B Document (FORBIDDEN)}$$
- **Database Engine Composite FK Enforcement (Decision D-12)**: Every company-scoped table establishes composite unique constraints `(company_id, id)` and referencing tables enforce composite foreign keys `FOREIGN KEY (company_id, target_id) REFERENCES target_table(company_id, id) ON DELETE RESTRICT`. SQLite engine automatically rejects cross-company references with a Foreign Key Violation error.
- **Repository Scope Enforcement**: Repositories validate that referenced foreign keys belong to `activeCompanyId` prior to command execution.

---

## 4. Scoped Uniqueness Constraints

Natural business keys (SKU, Customer Code, Invoice Number, Account Code, Voucher Number) are unique **ONLY WITHIN A SPECIFIC TENANT COMPANY**.
- **Tenant-Scoped Unique Constraints**:
  - `products`: `(company_id, sku)`
  - `customers`: `(company_id, code)`
  - `suppliers`: `(company_id, code)`
  - `accounts`: `(company_id, code)`
  - `warehouses`: `(company_id, code)`
  - `sales`: `(company_id, invoice_number)`
  - `purchases`: `(company_id, purchase_number)`
  - `journal_entries`: `(company_id, entry_number)`
  - `stock_receipts`: `(company_id, receipt_number)`
  - `currency_rate_history`: `(company_id, currency_code, target_currency, effective_date)` *(Fixes legacy defect R2)*
