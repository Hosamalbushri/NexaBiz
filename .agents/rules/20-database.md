# 20 — DATABASE & SCHEMA GOVERNANCE

## 1. Database Philosophy
1. **Durable Business Truth**: The database is the single, authoritative persistent repository of business truth in NexaBiz. It MUST NOT be treated as a temporary UI storage dump, key-value cache, or unstructured JSON payload container.
2. **Persistence Technologies**:
   * Primary relational store: **Drift / SQLite** with **SQLCipher** full-database encryption.
   * Local key-value state & cache: **Hive**.
   * Secure credential storage: **FlutterSecureStorage**.

---

## 2. Table Ownership & Multi-Tenancy
1. **Module Entity Ownership**: Every database table MUST be owned by exactly ONE module domain (e.g., `accounting_journals` owned by `accounting`, `inventory_items` owned by `inventory`). Cross-module direct SQL table writes are strictly prohibited.
2. **Mandatory Company Scope**: All business data tables MUST include a non-nullable `company_id` foreign key column to enforce strict multi-tenant isolation at the schema level. Global system tables (e.g., system setup, global permissions) MUST be explicitly documented as system-scoped.
3. **Primary Keys**: All database entities MUST use explicit, immutable primary keys (`UUID` string or `BIGINT` autoincrement ID). Cross-table references MUST enforce explicit foreign key constraints.

---

## 3. Relationships & Schema Integrity
1. **Foreign Key Integrity**: Foreign key constraints MUST be explicitly declared in Drift schema definitions. Cascade deletion (`ON DELETE CASCADE`) is FORBIDDEN on financial, ledger, and transactional tables.
2. **Cardinality & Optionality**: Nullability MUST accurately reflect business domain optionality. Mandatory business attributes MUST be declared as `NOT NULL` columns.
3. **Uniqueness Constraints**: Business natural keys (e.g., invoice numbers, SKU codes, journal entry numbers, account codes per tenant) MUST enforce database-level unique indexes `(company_id, natural_key)`.

---

## 4. Data Types & Financial Representations
1. **Monetary Values**: All monetary amounts MUST be stored as fixed-precision integers (e.g., minor currency units / cents) or exact high-precision decimal representation. Storing monetary values as IEEE 754 floating-point numbers (`REAL` / `double`) is STRICTLY FORBIDDEN.
2. **Currency Code Columns**: Every table storing monetary amounts MUST include an associated non-nullable `currency_code` column (e.g., `amount`, `currency_code`).
3. **Timestamps**: All temporal fields (`created_at`, `updated_at`, `posted_at`) MUST be stored in UTC standard format.

---

## 5. Immutability & Lifecycle Semantics
1. **Posted Immutability**: Rows representing posted financial transactions (`journal_entries`, `journal_lines`, `posted_invoices`, `stock_movements`) MUST NOT be updated or deleted after their status is marked as `POSTED`.
2. **Operational vs. Financial Data**: Operational draft documents MAY support field updates prior to posting. Once posted, financial projections and GL entries become immutable ledger history.
3. **Soft Deletion**: Operational master records (e.g., items, customers, accounts) MUST use explicit soft-deletion flags (`is_deleted`, `deleted_at`) to preserve historical integrity. Physical `DELETE` queries on master data with historical transactions are prohibited.
4. **NULL Semantics**: Column `NULL` values MUST represent absence of data, NOT hidden business defaults (e.g., `NULL` rate does NOT mean `1.0`; `NULL` account does NOT mean default account).

---

## 6. Projections, Caches & Sync Tables
1. **Read Projections**: Summary tables, cached balances, and reporting views MUST be derived from immutable underlying transactions and MUST be explicitly marked as `projection`.
2. **Sync Metadata**: Synchronization tables (`sync_queue`, `sync_audit`) MUST maintain change tracking version timestamps, entity GUIDs, sync status flags, and idempotency tokens.

---

## 7. Migration Safety & Schema Review Gates
1. **No Destructive Schema Modifications**: Dropping tables, dropping columns, renaming columns, or narrowing column data types without an explicit, approved multi-step migration path is FORBIDDEN.
2. **Migration Code Governance**: All Drift schema migrations MUST include backward-compatible step scripts and data transformation handlers.
3. **Index Optimization**: All query filter columns, join keys, foreign keys, and tenant isolation fields (`company_id`) MUST be explicitly indexed.
