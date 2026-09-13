# NEXABIZ ERP — RELATIONSHIP SPECIFICATION (RELATIONSHIPS.md)

## 1. Overview & Governance

This specification defines the logical relationship matrix across NexaBiz ERP domain entities. 

### Identity & Relationship Governance (Decision D-12)
All entity relationships enforce **UUID v7 (RFC 9562)** primary keys and foreign keys. Cross-company entity relationships are structurally prohibited at the database engine level via **Composite Tenant-Aware Foreign Keys** (`company_id, target_entity_id`) under `docs/database/D12_IDENTITY_DECISION.md`.

---

## 2. Canonical Relationship Matrix

| Parent Entity | Child Entity | Cardinality | Ownership Domain | Scope Boundary | Lifecycle & Delete Semantics |
| :--- | :--- | :---: | :--- | :--- | :--- |
| `Company` | `CompanyMembership` | 1:N | Core Tenancy | SYSTEM -> COMPANY | Managed via tenant access lifecycle |
| `Company` | `Product` | 1:N | Inventory | COMPANY | Soft deletion only; physical delete blocked if posted transactions exist |
| `Company` | `Warehouse` | 1:N | Inventory | COMPANY | Soft deletion only; blocked if active stock exists |
| `Company` | `Account` | 1:N | Accounting | COMPANY | Soft deletion only; blocked if journal entries exist |
| `Company` | `Customer` | 1:N | Customers | COMPANY | Soft deletion only |
| `Company` | `Supplier` | 1:N | Purchases | COMPANY | Soft deletion only |
| `Company` | `StockReceipt` | 1:N | Inventory | COMPANY | Document header lifecycle (`Draft` -> `Posted` -> `Unpost`) |
| `Company` | `StockIssue` | 1:N | Inventory | COMPANY | Document header lifecycle |
| `Company` | `StockReturn` | 1:N | Inventory | COMPANY | Document header lifecycle |
| `Company` | `StockTransfer` | 1:N | Inventory | COMPANY | Document header lifecycle |
| `Company` | `Sale` | 1:N | Sales | COMPANY | Document header lifecycle |
| `Company` | `Purchase` | 1:N | Purchases | COMPANY | Document header lifecycle |
| `Company` | `FinancialTransaction` | 1:N | Treasury | COMPANY | Document header lifecycle |
| `Company` | `JournalEntry` | 1:N | Accounting | COMPANY | General Ledger posting gateway (Sole Financial Authority) |
| `Company` | `FiscalYear` | 1:N | Accounting | COMPANY | Accounting calendar lifecycle |
| `User` | `CompanyMembership` | 1:N | Core Security | SYSTEM | User membership link |
| `ProductCategory` | `ProductCategory` | 1:N | Inventory | COMPANY | Self-referencing parent category tree |
| `ProductCategory` | `Product` | 1:N | Inventory | COMPANY | Product categorization |
| `Product` | `StockMovementLine` | 1:N | Inventory | COMPANY | Document line item reference to product master |
| `Product` | `StockMovementLedger` | 1:N | Inventory | COMPANY | Authoritative physical stock ledger history |
| `Product` | `InventoryCostLayer` | 1:N | Inventory | COMPANY | Inbound FIFO cost layer valuation entries |
| `Product` | `ProductWarehouseStock` | 1:N | Inventory | COMPANY | Derived stock balance projection per location |
| `Product` | `SaleItem` | 1:N | Sales | COMPANY | Commercial sale line reference |
| `Product` | `PurchaseItem` | 1:N | Purchases | COMPANY | Commercial purchase line reference |
| `Warehouse` | `StockReceipt` | 1:N | Inventory | COMPANY | Receiving warehouse location |
| `Warehouse` | `StockIssue` | 1:N | Inventory | COMPANY | Issuing warehouse location |
| `Warehouse` | `StockTransfer` (Source) | 1:N | Inventory | COMPANY | Source warehouse location |
| `Warehouse` | `StockTransfer` (Target) | 1:N | Inventory | COMPANY | Target warehouse location |
| `Warehouse` | `ProductWarehouseStock` | 1:N | Inventory | COMPANY | Stock projection location binding |
| `Warehouse` | `WarehouseAccountingBinding` | 1:1 | Inventory / Accounting | COMPANY | Warehouse GL account mapping |
| `StockReceipt` | `StockMovementLine` | 1:N | Inventory | INHERITED COMPANY | Lines governed by document aggregate lifecycle |
| `StockIssue` | `StockMovementLine` | 1:N | Inventory | INHERITED COMPANY | Lines governed by document aggregate lifecycle |
| `StockReturn` | `StockMovementLine` | 1:N | Inventory | INHERITED COMPANY | Lines governed by document aggregate lifecycle |
| `StockTransfer` | `StockMovementLine` | 1:N | Inventory | INHERITED COMPANY | Lines governed by document aggregate lifecycle |
| `StockMovementLine` | `StockMovementLedger` | 1:N (0, 1, or N) | Inventory | COMPANY | 1 line may produce 0, 1, or N physical ledger effects |
| `InventoryCostLayer` | `InventoryCostConsumption` | 1:N | Inventory | COMPANY | Traceable FIFO cost layer consumption |
| `StockMovementLedger` | `InventoryCostConsumption` | 1:N | Inventory | COMPANY | Outbound movement to consumed layer trace |
| `Sale` | `SaleItem` | 1:N | Sales | INHERITED COMPANY | Detail items governed by parent sale lifecycle |
| `Sale` | `SalePayment` | 1:N | Sales / Treasury | INHERITED COMPANY | Payment settlements for sale invoice |
| `Purchase` | `PurchaseItem` | 1:N | Purchases | INHERITED COMPANY | Detail items governed by parent purchase lifecycle |
| `Purchase` | `PurchasePayment` | 1:N | Purchases / Treasury | INHERITED COMPANY | Payment settlements for purchase invoice |
| `Customer` | `Sale` | 1:N | Sales | COMPANY | Customer commercial invoices |
| `Customer` | `FinancialTransaction` | 1:N | Treasury | COMPANY | Customer cash receipts |
| `Supplier` | `Purchase` | 1:N | Purchases | COMPANY | Vendor purchase invoices |
| `Supplier` | `FinancialTransaction` | 1:N | Treasury | COMPANY | Vendor cash payments |
| `Account` | `Account` | 1:N | Accounting | COMPANY | Chart of Accounts parent-child hierarchy |
| `Account` | `AccountCurrencyBalance` | 1:N | Accounting | INHERITED COMPANY | Multi-currency balance sub-entities per account |
| `Account` | `JournalLine` | 1:N | Accounting | INHERITED COMPANY | General Ledger debit/credit lines |
| `CashRegister` | `FinancialTransaction` | 1:N | Treasury | COMPANY | Cash drawer receipt/payment vouchers |
| `FiscalYear` | `AccountingPeriod` | 1:N | Accounting | INHERITED COMPANY | Monthly fiscal periods within year |
| `AccountingPeriod` | `PeriodClosingRecord` | 1:1 | Accounting | INHERITED COMPANY | Period closing audit lock snapshot |
| `AccountingPeriod` | `JournalEntry` | 1:N | Accounting | COMPANY | Journal entries posted within fiscal period |
| `JournalEntry` | `JournalLine` | 1:N | Accounting | INHERITED COMPANY | Debit and credit detail lines (Set-level balanced) |
| `Currency` | `JournalLine` | 1:N | Accounting | INHERITED COMPANY | Currency associated with journal line |
| `Currency` | `CurrencyRate` | 1:N | Accounting | COMPANY | FX exchange rates for currency pair |
| `Currency` | `CurrencyRateHistory` | 1:N | Accounting | COMPANY | Historical FX rate changes for currency |

---

## 3. Aggregate Lifecycle & Multi-Line Effect Standards

1. **Draft Aggregate Lifecycle**: Draft child rows (e.g. `sale_items`, `stock_movement_lines`) may be deleted or modified as part of the draft document aggregate lifecycle prior to posting.
2. **Posted Immutability**: Posted child rows and ledger entries are immutable and must not be physically removed through ordinary editing.
3. **Multi-Line Effect Mapping**: One document line item (`StockMovementLine`) may produce zero, one, or multiple posted movement effects (`StockMovementLedger`) or costing effects (e.g. multiple FIFO layer consumptions for a single outbound line).
