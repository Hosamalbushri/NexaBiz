# NEXABIZ ERP — CANONICAL DATABASE BLUEPRINT (DATABASE_BLUEPRINT.md)

## 0. EXECUTIVE SUMMARY & READ-ONLY MODE DECLARATION

This document defines the canonical database architecture blueprint for NexaBiz ERP (`nexabiz.sqlite`). 

```text
STRICT READ-ONLY / DESIGN-ONLY MODE
No production Dart source code was modified.
No Laravel backend code was modified.
No Drift database schemas were modified.
No SQL migration scripts were executed.
No database files were modified or deleted.
No business rules or behaviors were changed.
```

---

## 1. IDENTITY ARCHITECTURE & DECISION D-12 STATUS

### 1.1 Semantic Identity Requirement
The system requires distinguishable entity, document, operation/event, posting, and synchronization identities where required by business semantics.

### 1.2 Decision D-12 Status
```text
RESOLVED AND FROZEN UNDER DECISION D-12 (D12_IDENTITY_DECISION.md)
Technical identity is frozen as UUID v7 (RFC 9562) across all canonical entities.
Tenant-safe isolation is enforced via Composite Tenant-Aware Foreign Keys (company_id, target_id).
Offline-first creation uses locally generated UUID v7 keys without server roundtrips.
Idempotency identity is decoupled from entity identity via explicit operation idempotency keys.
```
The identity architecture, primary key strategy, foreign key integrity rules, aggregate ownership boundaries, and idempotency models are formally frozen under `docs/database/D12_IDENTITY_DECISION.md`.

---

## 2. SYNCHRONIZATION ARCHITECTURE & DECISION D-11 STATUS

### 2.1 Non-Negotiable Semantic Requirement
> After a successful local authoritative business commit, required synchronization intent must remain durably recoverable according to the final sync architecture.

### 2.2 Current Codebase Evidence
Forensic audit identifies two existing sync persistence mechanisms in the current codebase:
1. **SQLite `sync_operations`**: Relational table in SQLite.
2. **Hive `sync_queue`**: Key-value store managed via Hive.

### 2.3 Decision D-11 Status
```text
UNRESOLVED UNDER DECISION D-11
Neither SQLite sync_operations nor Hive sync_queue is declared the final canonical authority.
The physical synchronization storage model remains UNRESOLVED under D-11.
```

---

## 3. LIFECYCLE & GENERIC VOID ARCHITECTURE (DECISION D-14 STATUS)

### 3.1 Domain Lifecycle Classification
The system distinguishes five separate operational lifecycles:
1. **Inventory Unpost**: Operational document state change (`Posted -> Draft`) that removes posted inventory ledger and costing effects and triggers deterministic recalculation from remaining valid history. Does NOT create a reversing journal entry.
2. **Accounting Reversal**: Posting an explicit reversing General Ledger journal entry with swapped debit/credit values.
3. **Generic Void**: Operational document cancellation without removal of posted historical ledger audit trail.
4. **Generic Correction**: Adjusting entry modifying financial or inventory balances.
5. **Sales Return**: Commercial document header for customer returns valued using current product cost at the posting moment.

### 3.2 Decision D-14 Status
```text
UNRESOLVED UNDER DECISION D-14
Generic non-inventory financial lifecycle behavior, generic GL void schema, 
and correction structures remain UNRESOLVED under D-14.
This does NOT invalidate the accepted inventory unpost behavior.
```

---

## 4. INVENTORY AUTHORITY & COSTING ANALYSIS

### 4.1 Authoritative Stock State vs. Derived Balance Projection
- **Authoritative Physical Stock History**: `stock_movement_ledgers` is the authoritative ledger of all posted inventory movements. 
  - *Forensic Question*: If `stock_movement_ledgers` is deleted, can authoritative stock history be reconstructed? **NO.**
- **Derived Stock Balance Projection**: `product_warehouse_stocks` is a derived read projection.
  - *Forensic Question*: If `product_warehouse_stocks` is deleted, can authoritative stock state be reconstructed? **YES**, by recalculating sum of quantities from `stock_movement_ledgers`.

### 4.2 Independent Costing Models (WAC vs FIFO)
Products independently select **WAC** (Weighted Average Cost) or **FIFO** (First-In, First-Out). LIFO is strictly prohibited.
- **WAC State**: Product average cost is a derived state recalculated upon inbound posting.
- **FIFO State**: Inbound movements create `inventory_cost_layers`; outbound movements create traceable records in `inventory_cost_consumptions`.

### 4.3 Costing Method Change Rule
A product's costing method can change ONLY when:
1. All relevant transactions/entries are posted/resolved;
2. Product stock balance is zero;
3. No unresolved effects remain.

---

## 5. GENERAL LEDGER POSTING & BALANCE INVARIANT

### 5.1 Sole Financial Authority
`JournalPostingService` is the sole financial writer. All General Ledger entries post through this gateway.

### 5.2 Set-Level Journal Balance Invariant
Journal balancing is a set-level invariant enforced at the transaction boundary:
$$\sum \text{Base Debits for Journal} = \sum \text{Base Credits for Journal}$$
Row-level `CHECK(debit == credit)` constraints do not apply to individual journal lines.

---

## 6. TENANCY & MULTI-TENANT CLASSIFICATION

Every entity is classified into one of four scope tiers:
1. **SYSTEM**: System management entities (`canonical_db_metadata`, `users`).
2. **GLOBAL REFERENCE**: Global catalog reference data (`currencies`). Shared across companies.
3. **COMPANY**: Tenant-owned entities containing `company_id` (`companies`, `warehouses`, `products`, `accounts`, `sales`, `purchases`, `stock_receipts`, `journal_entries`).
4. **INHERITED COMPANY**: Detail child tables inheriting company scope strictly through their parent header (`sale_items`, `purchase_items`, `stock_movement_lines`, `journal_lines`).

---

## 7. PHASE 2 READINESS VERDICT

```text
PHASE 2 STATUS: BLOCKED
```
*Justification*: Open decisions **D-11**, **D-12**, and **D-14** remain unresolved and materially affect physical database schema design. Physical schema implementation cannot proceed until these decisions are explicitly resolved by project stakeholders.
