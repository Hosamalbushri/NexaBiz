# NEXABIZ ERP — DECISION D-12: IDENTITY & KEY ARCHITECTURE (D12_IDENTITY_DECISION.md)

## 0. DECISION STATUS & READ-ONLY MODE DECLARATION

```text
DECISION D-12 STATUS: APPROVED & FROZEN
```

```text
STRICT READ-ONLY / DESIGN-ONLY EXECUTION
No Dart source code was modified.
No Laravel backend code was modified.
No Drift database schemas were modified.
No SQL migration scripts were executed.
No SQLite database files were modified or deleted.
```

---

## 1. EXECUTIVE SUMMARY

Decision D-12 establishes the single canonical identity, foreign key, synchronization identity, idempotency, and tenant-isolation architecture for NexaBiz ERP (`nexabiz.sqlite`). 

### Core Architectural Decisions:
1. **Primary Technical Identity**: **UUID v7 (RFC 9562)** is the sole physical primary key and general-purpose foreign key data type across all canonical entities. Local integer autoincrement primary keys and integer foreign keys are **STRICTLY PROHIBITED** as domain identities.
2. **Tenant-Safe Foreign Keys**: Multi-tenant reference boundaries are enforced at the database engine level using **Composite Tenant-Aware Foreign Keys** (`(company_id, target_entity_id)`). This renders cross-company record references structurally impossible.
3. **Offline-First Creation**: Entities are assigned a 128-bit time-ordered UUID v7 locally upon creation. No server connectivity or server-generated ID sequence is required prior to local persistence.
4. **Operation Identity & Refined Idempotency**: Operation identity (`idempotency_key`) is strictly decoupled from entity identity (`entity_id`). The legacy `source_document_id` idempotency shortcut is replaced by a deterministic, lifecycle-aware `idempotency_key` model (`UUID v7` or `hash(company_id:action:source_doc_id:sequence)`).
5. **Polymorphic Reference Resolution**: Polymorphic `(source_document_type, source_document_id)` pairs are constrained to UUID v7 technical identities and enforced through tenant-aware runtime validation and explicit source mapping rules.

---

## 2. CURRENT-STATE EVIDENCE & FORENSIC AUDIT

A forensic audit of the NexaBiz codebase revealed the following structural issues and patterns:

### 2.1 Primary Key Contradictions
- Current Drift schemas (e.g. `products_table.dart`, `companies_table.dart`, `stock_movement_ledgers_table.dart`) define dual identifiers: an SQLite `integer().autoIncrement()` column (`id`) alongside a string `text()` column (`uuid`).
- In several modules, relationships use `uuid` strings, while others pass integer `id` values, creating key ambiguity between local surrogate keys and global identities.

### 2.2 Foreign Key Vulnerabilities
- Existing tables use single-column text or integer foreign keys (e.g. `accountUuid`, `warehouseId`, `categoryUuid`).
- Single-column FKs (`FOREIGN KEY (warehouse_id) REFERENCES warehouses(id)`) validate that the warehouse exists, but **DO NOT** validate that the warehouse belongs to the same `company_id` as the transaction.

### 2.3 Polymorphic Reference Evidence
- `stock_movement_ledgers` uses `sourceDocumentType` + `sourceDocumentId` (text UUID) + `sourceLineUuid`.
- `journal_entries` uses `sourceType` + `sourceId` (text UUID).
- `AccountingSourceReference` (`lib/modules/accounting/domain/foundation/accounting_source_reference.dart`) explicitly enforces string UUIDs and throws `ArgumentError` if a local integer ID is passed as a cross-domain source reference.

### 2.4 Sync & Idempotency Evidence
- `HttpRemoteSyncApi` transmits `operation_id` as `idempotency_key` alongside `entity_id` and `entity_type`.
- Hive `sync_queue` and SQLite `sync_operations` both track synchronization operations separately from entity records.

---

## 3. CHOSEN TECHNICAL IDENTITY STRATEGY (UUID v7)

NexaBiz adopts **UUID v7 (RFC 9562)** as the standard technical identity across all canonical tables.

### 3.1 Why UUID v7 Was Selected
1. **Time-Ordered Monotonicity**: UUID v7 incorporates a 48-bit Unix epoch timestamp prefix followed by 74 bits of randomness/monotonic counter. This guarantees monotonically increasing keys, eliminating B-tree index fragmentation in SQLite and remote MySQL/PostgreSQL databases.
2. **Offline-First Autonomy**: Mobile and desktop clients generate canonical UUID v7 keys locally without network roundtrips or central lock coordination.
3. **Deterministic Global Uniqueness**: 128-bit collision resistance ensures zero primary key collisions across multi-device distributed environments.
4. **Single-Key Architecture**: Eliminates dual-key complexity (integer autoincrement + UUID string), reducing storage overhead, code ambiguity, and translation layer defects.

### 3.2 Physical Storage Representation
- **SQLite Client (`nexabiz.sqlite`)**: Stored as 36-character string formatted text (`TEXT`) or 16-byte raw BLOB (`BLOB`), with text representation used for JSON API serialization.
- **Laravel Backend**: Stored as 16-byte binary UUID / string UUID (`uuid` column type).

---

## 4. TENANT-SAFE FOREIGN KEY ARCHITECTURE

To strictly satisfy the **NexaBiz Tenancy Rule** (Company A must never reference Company B entities), single-column foreign keys are prohibited for company-scoped relationships.

### 4.1 Composite Foreign Key Pattern
Every company-scoped table defines a composite unique key on `(company_id, id)`. All child tables and referencing tables include `company_id` and establish composite foreign key constraints:

```sql
-- Parent Table Definition
CREATE TABLE products (
    id TEXT NOT NULL PRIMARY KEY, -- UUID v7
    company_id TEXT NOT NULL,
    sku TEXT NOT NULL,
    name TEXT NOT NULL,
    CONSTRAINT uq_products_company_id UNIQUE (company_id, id)
);

-- Child Table Definition
CREATE TABLE sale_items (
    id TEXT NOT NULL PRIMARY KEY, -- UUID v7
    sale_id TEXT NOT NULL,
    company_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    quantity REAL NOT NULL,
    -- Enforces that product_id belongs to the exact same company_id as sale_items
    CONSTRAINT fk_sale_items_product 
        FOREIGN KEY (company_id, product_id) 
        REFERENCES products(company_id, id) 
        ON DELETE RESTRICT
);
```

### 4.2 Structural Guarantee
If a user attempts to create a `SaleItem` under `Company A` referencing a `Product` owned by `Company B`:
- `sale_items.company_id` = `'COMP-A'`
- `sale_items.product_id` = `'PROD-B-UUID'`
- The database engine searches `products` for `(company_id = 'COMP-A', id = 'PROD-B-UUID')`.
- Because `PROD-B-UUID` has `company_id = 'COMP-B'`, the composite lookup fails.
- **SQLite REJECTS the transaction with a Foreign Key Violation at the database engine layer.**

---

## 5. AGGREGATE IDENTITY CLASSIFICATION

Every canonical entity is classified as either an **Aggregate Root** or an **Aggregate Child**.

### 5.1 Aggregate Roots (29 Entities)
Independent entities with their own lifecycle, master configuration, or transaction header identity:
- `Company`, `User`, `CompanyMembership`, `Currency`, `ProductCategory`, `Warehouse`, `Product`, `Customer`, `Supplier`, `Account`, `CashRegister`, `VoucherBook`, `StockReceipt`, `StockIssue`, `StockReturn`, `StockTransfer`, `StockMovementLedger`, `InventoryCostLayer`, `ProductWarehouseStock`, `WarehouseAccountingBinding`, `InventoryAuditTrail`, `Sale`, `Purchase`, `FinancialTransaction`, `FiscalYear`, `JournalEntry`, `CurrencyRate`, `CurrencyRateHistory`, `CanonicalDbMetadata`.

### 5.2 Aggregate Children (10 Entities)
Sub-entities whose lifecycle is strictly bound to their parent header. Children cannot exist independently and are deleted/modified through parent aggregate actions:
- `StockMovementLine` (Child of Inventory Document Header)
- `InventoryCostConsumption` (Child of `StockMovementLedger` / `InventoryCostLayer`)
- `SaleItem` (Child of `Sale`)
- `SalePayment` (Child of `Sale`)
- `PurchaseItem` (Child of `Purchase`)
- `PurchasePayment` (Child of `Purchase`)
- `AccountingPeriod` (Child of `FiscalYear`)
- `PeriodClosingRecord` (Child of `AccountingPeriod`)
- `JournalLine` (Child of `JournalEntry`)
- `AccountCurrencyBalance` (Child of `Account`)

---

## 6. POLYMORPHIC REFERENCE RESOLUTION

Unsafe polymorphic `(type, id)` pairs are resolved into tenant-safe structural designs:

1. **`stock_movement_ledgers` (`source_document_type`, `source_document_id`)**:
   - `source_document_id` MUST store the UUID v7 technical ID of the originating document header.
   - `stock_movement_ledgers` stores `company_id`. The domain poster validates `company_id` parity prior to commit.
2. **`journal_entries` (`source_type`, `source_id`)**:
   - Encapsulated by `AccountingSourceReference(sourceType, sourceId)`.
   - `sourceId` MUST be a UUID v7 string. Integer local IDs are rejected by runtime assertion.
3. **`stock_returns` (`original_document_id`)**:
   - Stores the UUID v7 technical identity of the parent sale/purchase invoice being returned.
4. **`journal_lines` (`party_type`, `party_id`)**:
   - Validated against explicit party types (`customer`, `supplier`) and checked against active tenant scope.

---

## 7. BUSINESS UNIQUE IDENTITIES & LIFECYCLE RULES

Business identities are human-readable identifiers (codes, SKUs, numbers). They **MUST NOT** be used as general-purpose foreign keys.

| Business Identifier | Scoped Uniqueness Constraint | Immutable Stage | Reusability Rule |
| :--- | :--- | :--- | :--- |
| SKU | `(company_id, sku)` | Post / Initial Transaction | Never Reusable |
| Customer Code | `(company_id, code)` | First Transaction | Never Reusable |
| Supplier Code | `(company_id, code)` | First Transaction | Never Reusable |
| Account Code | `(company_id, code)` | First GL Journal | Never Reusable |
| Warehouse Code | `(company_id, code)` | First Stock Movement | Never Reusable |
| Invoice Number | `(company_id, invoice_number)` | Immediately on Posting | Never Reusable |
| Purchase Number | `(company_id, purchase_number)`| Immediately on Posting | Never Reusable |
| Journal Entry Number | `(company_id, entry_number)` | Immediately on Posting | Never Reusable |
| Receipt Number | `(company_id, receipt_number)` | Immediately on Posting | Never Reusable |
| Issue Number | `(company_id, issue_number)` | Immediately on Posting | Never Reusable |
| Transfer Number | `(company_id, transfer_number)`| Immediately on Posting | Never Reusable |
| Voucher Number | `(company_id, voucher_number)` | Immediately on Posting | Never Reusable |

---

## 8. DOCUMENT NUMBER VS ENTITY ID SEPARATION

```text
Technical Entity ID (UUID v7)  ≠  Business Document Number (Sequential Code)
```

Example for Purchase Invoice:
- `id` = `018c3a9f-7b12-7000-8000-123456789abc` (UUID v7, used for PK, FKs, sync, joins)
- `purchase_number` = `PO-2026-00042` (Generated from `VoucherBook` sequence, human reference)

---

## 9. SYNC IDENTITY & IDEMPOTENCY MODEL

### 9.1 Offline-First Sync Identity
```text
Create Entity Locally
   ↓ (Assign local UUID v7 as entity_id)
Persist Entity to SQLite
   ↓ (Within local ACID transaction)
Create SyncOperation (Assign local UUID v7 as operation_id / idempotency_key)
   ↓ (Queue for async upload)
Push to Remote Server
   ↓ (Server validates idempotency_key + company_id)
Ack & Mark Synced
```

### 9.2 Refined Idempotency Model
The legacy rule `idempotency_key OR source_document_id` is **REPLACED**. `source_document_id` alone is insufficient because one document produces multiple operational lifecycle events (posting, reversal, partial payment, unpost/repost).

**Canonical Idempotency Formula**:
Every synchronization operation carries an explicit `idempotency_key` constructed as:
$$\text{idempotency\_key} = \text{UUID v7 (assigned at sync intent creation)}$$
OR for deterministic event replay:
$$\text{idempotency\_key} = \text{SHA256}(\text{company\_id} \mathbin{\Vert} \text{action\_type} \mathbin{\Vert} \text{source\_document\_id} \mathbin{\Vert} \text{sequence\_counter})$$

---

## 10. ENTITY-BY-ENTITY IDENTITY MATRIX

| Entity Name | Scope Tier | Aggregate Class | Technical ID | Business ID | Parent Entity | Tenant FK Strategy | Sync Identity |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `canonical_db_metadata` | SYSTEM | Root | Key (Text) | `key` | None | N/A | Local Only |
| `users` | SYSTEM | Root | UUID v7 | `username` | None | N/A | User Sync ID |
| `companies` | COMPANY Root | Root | UUID v7 | `code` | None | N/A | Company UUID |
| `company_memberships` | COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, user_id)` | Membership UUID |
| `currencies` | GLOBAL REF | Root | Code (ISO 4217) | `code` | None | Global Standard | Global Code |
| `product_categories` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, parent_id)` | Category UUID |
| `warehouses` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, id)` | Warehouse UUID |
| `products` | COMPANY | Root | UUID v7 | `sku` | `Company` | Composite `(company_id, category_id)` | Product UUID |
| `customers` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, account_id)` | Customer UUID |
| `suppliers` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, account_id)` | Supplier UUID |
| `accounts` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, parent_id)` | Account UUID |
| `cash_registers` | COMPANY | Root | UUID v7 | `name` | `Company` | Composite `(company_id, account_id)` | Register UUID |
| `voucher_books` | COMPANY | Root | UUID v7 | `code` | `Company` | Composite `(company_id, id)` | VoucherBook UUID |
| `stock_receipts` | COMPANY | Root | UUID v7 | `receipt_number` | `Company` | Composite `(company_id, warehouse_id)` | Receipt UUID |
| `stock_issues` | COMPANY | Root | UUID v7 | `issue_number` | `Company` | Composite `(company_id, warehouse_id)` | Issue UUID |
| `stock_returns` | COMPANY | Root | UUID v7 | `return_number` | `Company` | Composite `(company_id, warehouse_id)` | Return UUID |
| `stock_transfers` | COMPANY | Root | UUID v7 | `transfer_number` | `Company` | Composite `(company_id, src_wh_id)` | Transfer UUID |
| `stock_movement_lines` | INHERITED | Child | UUID v7 | None | Inventory Doc Header | Parent Header Cascade | Line UUID |
| `stock_movement_ledgers`| COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, product_id)` | Ledger UUID |
| `inventory_cost_layers` | COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, product_id)` | CostLayer UUID |
| `inventory_cost_consumptions`| COMPANY | Child | UUID v7 | None | `StockMovementLedger` | Composite `(company_id, layer_id)` | Consumption UUID |
| `product_warehouse_stocks`| COMPANY | Root | UUID v7 | None | `Product` / `Warehouse` | Composite `(company_id, product_id)` | Projection UUID |
| `warehouse_accounting_bindings`| COMPANY | Root | UUID v7 | None | `Warehouse` | Composite `(company_id, warehouse_id)`| Binding UUID |
| `inventory_audit_trail` | COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, id)` | Audit Log UUID |
| `sales` | COMPANY | Root | UUID v7 | `invoice_number` | `Company` | Composite `(company_id, customer_id)` | Sale UUID |
| `sale_items` | INHERITED | Child | UUID v7 | None | `Sale` | Composite `(company_id, product_id)` | SaleItem UUID |
| `sale_payments` | INHERITED | Child | UUID v7 | None | `Sale` | Composite `(company_id, register_id)` | Payment UUID |
| `purchases` | COMPANY | Root | UUID v7 | `purchase_number` | `Company` | Composite `(company_id, supplier_id)` | Purchase UUID |
| `purchase_items` | INHERITED | Child | UUID v7 | None | `Purchase` | Composite `(company_id, product_id)` | PurchaseItem UUID |
| `purchase_payments` | INHERITED | Child | UUID v7 | None | `Purchase` | Composite `(company_id, register_id)` | Payment UUID |
| `financial_transactions`| COMPANY | Root | UUID v7 | `voucher_number` | `Company` | Composite `(company_id, register_id)`| Transaction UUID |
| `fiscal_years` | COMPANY | Root | UUID v7 | `year_name` | `Company` | Composite `(company_id, id)` | FiscalYear UUID |
| `accounting_periods` | INHERITED | Child | UUID v7 | `period_name` | `FiscalYear` | Parent Fiscal Year Link | Period UUID |
| `period_closing_records`| INHERITED | Child | UUID v7 | None | `AccountingPeriod` | Parent Period Link | Closing UUID |
| `journal_entries` | COMPANY | Root | UUID v7 | `entry_number` | `Company` | Composite `(company_id, id)` | Journal UUID |
| `journal_lines` | INHERITED | Child | UUID v7 | None | `JournalEntry` | Composite `(company_id, account_id)` | JournalLine UUID |
| `account_currency_balances`| INHERITED | Child | UUID v7 | None | `Account` | Composite `(company_id, account_id)` | Balance UUID |
| `currency_rates` | COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, id)` | CurrencyRate UUID |
| `currency_rate_history` | COMPANY | Root | UUID v7 | None | `Company` | Composite `(company_id, currency_code)`| History UUID |

---

## 11. MIGRATION IMPLICATIONS

Existing legacy integer IDs (e.g. integer `id` columns in SQLite) will undergo a deterministic mapping pass during physical schema migration:
1. Legacy integer IDs are preserved in a temporary mapping table (`legacy_id_mappings`) during migration.
2. Domain entities receive new canonical UUID v7 values.
3. Foreign key references across all tables are translated to corresponding UUID v7 identities using `legacy_id_mappings`.
4. Legacy integer columns are removed from domain schemas.

---

## 12. REJECTED ALTERNATIVES

1. **Integer Autoincrement**: Rejected due to offline-first collision risk and sync translation complexity.
2. **UUID v4**: Rejected due to index fragmentation (random insert distribution in B-tree indexes).
3. **ULID**: Rejected due to non-standard database and backend support compared to RFC 9562 UUID v7.
4. **Dual-Key (Int + UUID)**: Rejected due to mapping code overhead and potential synchronization drift between surrogate and global keys.

---

## 13. REMAINING RISKS & MITIGATIONS

- **Risk**: 36-byte string representation increases database file size slightly compared to 8-byte integers.
  - *Mitigation*: Negligible overhead for modern hardware (< 5 MB per 100,000 rows); offset by elimination of translation tables and index splitting.
- **Risk**: Legacy source code referencing integer `id` fields.
  - *Mitigation*: Static analysis and migration plan will systematically update repositories and models to use UUID v7 string fields.

---

## 14. EXPLICIT INVARIANTS

1. **Identity Invariant**: Every persistent canonical entity has exactly one canonical technical identity (`UUID v7`).
2. **Business Identity Invariant**: Human business numbers are not general-purpose foreign keys.
3. **Tenant Isolation Invariant**: Foreign keys must be composite (`company_id, target_id`) to structurally prevent cross-tenant references.
4. **Offline Independence Invariant**: Entities can be created locally without network connectivity or server-generated sequence numbers.
5. **Idempotency Invariant**: Synchronization operations carry explicit `idempotency_key` values decoupled from entity IDs to ensure safe retry without duplicate side effects.

---

## 15. DECISION CLOSURE & AUTHORIZATION

Decision D-12 is formally **RESOLVED AND FROZEN**. All Phase 2 canonical database designs and blueprint documents must conform strictly to `D12_IDENTITY_DECISION.md`.
