# NEXABIZ ERP — MASTER ARCHITECTURE DISCOVERY, CURRENT-SYSTEM ANALYSIS & MIGRATION ROADMAP

---

## 1. Executive Summary

NexaBiz is a hybrid multi-platform Enterprise Resource Planning (ERP) application featuring a Flutter/Dart client (`lib/`) and a Laravel/PHP server (`backend-laravel/`). 

An exhaustive forensic analysis of the source code confirms that while the application features well-isolated domain modules under `lib/modules/`, it is structurally constrained by a multi-database persistence layer comprising five distinct SQLite databases (`inventory.sqlite`, `accounting.sqlite`, `sales.sqlite`, `customers.sqlite`, `receipts_payments.sqlite`). This multi-database layout breaks ACID database transaction atomicity across cross-domain workflows (e.g., Sale -> Stock Movement -> Costing -> Journal Entry).

The primary objective of this roadmap is **NOT** to rebuild the application greenfield, but to execute an **incremental, non-destructive, adapter-driven architectural migration** toward a single encrypted canonical database (`nexabiz.sqlite`) powered by centralized business authorities.

---

## 2. What NexaBiz Should Become

NexaBiz must evolve into a canonical, modular, offline-first ERP system characterized by:
1. **Offline-First & Local-First Autonomy**: The client application operates completely independently of network or server connectivity.
2. **Structural Tenant Isolation**: Strict isolation preventing `Company A` from reading or writing `Company B` data across repositories, DAOs, and domain services.
3. **Single Canonical Database (`nexabiz.sqlite`)**: Replacement of legacy per-module databases with a single encrypted SQLite database supporting multi-table ACID transactions (`BEGIN ... COMMIT / ROLLBACK`).
4. **Single Centralized Business Authorities**:
   - **Central Accounting Gateway**: Authoritative gate enforcing immutable posted records (`POSTED`), journal validation, and semantic Account Roles (`SALES_REVENUE`, `INVENTORY_ASSET`, `COGS`, `AR_CONTROL`, etc.).
   - **Central Inventory Movement Engine**: Single movement ledger powering stock balance calculations, costing layer consumption, and stock operations (Receipt, Issue, Transfer, Return, Adjustment).
   - **Central Costing Engine**: Deterministic valuation supporting FIFO, LIFO, and Weighted Average Costing (WAC).
5. **Clean Architecture & Ports/Adapters**: Presentation layers decoupled from domain logic; domain logic decoupled from infrastructure.

---

## 3. Current Architecture

### Client Stack (`lib/`)
* **State Management**: Riverpod (`flutter_riverpod`)
* **Persistence Layer**: Drift (SQLite ORM) with separate per-module database definitions:
  - `InventoryDatabase` (`lib/modules/inventory/shared/data/database/inventory_database.dart`)
  - `AccountingDatabase` (`lib/modules/accounting/shared/data/database/accounting_database.dart`)
  - `SalesDatabase` (`lib/modules/sales/shared/data/database/sales_database.dart`)
  - `CustomersDatabase` (`lib/modules/customers/shared/data/database/customers_database.dart`)
  - `ReceiptsPaymentsDatabase` (`lib/modules/receipts_payments/shared/data/database/receipts_payments_database.dart`)
* **Routing**: GoRouter (`go_router`) with module-level route builders (`AppRoutes`, `InventoryRoutes`, `AuthRoutes`).
* **Synchronization & Offline Engine**: Custom 3-way merger, conflict resolver, and sync queue backed by Hive & Drift tables (`sync_operations`, `sync_changes`).

### Server Stack (`backend-laravel/`)
* **Framework**: Laravel 11 with custom package architecture in `packages/NexaBiz/`:
  - `NexaBiz/Identity`: User, Company, Role, AuthSession, JWT.
  - `NexaBiz/Entitlements`: Subscriptions, Plans, Features, Usage Mappings.
  - `NexaBiz/Synchronization`: Central sync change log & delta distribution API.
  - `NexaBiz/Initialization`: Bootstrap & seed endpoints.

---

## 4. Target Architecture

```text
Presentation Layer (Pages & UI Widgets)
        ↓
Notifier / Controller Layer (Riverpod Notifiers)
        ↓
Application Services / Use Cases
        ↓
Domain Services & Business Authorities (Costing, Movement Engine, Accounting Gateway)
        ↓
Repository & Gateway Ports
        ↓
Repository Implementations & Adapters
        ↓
Canonical Local Database (nexabiz.sqlite)
```

---

## 5. Current vs Target Gap Analysis

| Architectural Dimension | Current State | Target State | Gap / Risk |
| ----------------------- | ------------- | ------------ | ---------- |
| **Database Atomicity** | 5 separate SQLite files | Single `nexabiz.sqlite` DB | **HIGH**: Cross-database operations currently lack `BEGIN/COMMIT` atomicity. |
| **Tenant Isolation** | Applied via manual `where((t) => t.companyId.equals(...))` | Enforced structurally at Connection / Gateway level | **MEDIUM**: Risk of developer omitting `companyId` in custom queries. |
| **Accounting Posting** | Fragmented across `DocumentPostingOrchestrator`, `InventoryAccountingPosterAdapter`, and `SalesPostingOrchestrator` | Central Accounting Gateway (`JournalPostingService`) | **HIGH**: Multiple posting bridges create inconsistent journal formats. |
| **Inventory Stock Source** | Calculated via `stock_movement_ledgers` AND queried from `product_warehouse_stocks` cache | Authoritative Stock Movement Ledger projection | **MEDIUM**: Stock projection cache desynchronization. |
| **Costing Calculation** | `InventoryCostCalculatorImpl` + product import preview logic | Central Costing Engine | **LOW**: Duplicate costing routines in import logic. |

---

## 6. Business Authority Map

* **Stock Balance Authority**: `InventoryLedgerServiceImpl` & `StockValidationServiceImpl` (`lib/modules/inventory/stock_movements/`)
* **Stock Movement Authority**: `PostingEngineImpl` & `PostingCoordinatorImpl`
* **Inventory Cost Authority**: `InventoryCostCalculatorImpl` & `CostLayerServiceImpl`
* **Customer Balance Authority**: `CustomerSubledgerQueryAdapter` (`lib/modules/customers/`)
* **Account Balance Authority**: `JournalRepositoryImpl` & `GeneralLedger`
* **Journal Posting Authority**: `JournalPostingService` & `CentralAccountingGateway`
* **Currency Authority**: `CurrencyRateRepositoryImpl` & `InventoryValuationCurrencyService`
* **Tenant Context Authority**: `TenantContext` & `SessionContextPort`

* **DUPLICATE AUTHORITY FINDINGS**:
  - **Stock Balance**: Calculated both via `stock_movement_ledgers` aggregation AND queried from `product_warehouse_stocks` projections in some legacy screens.
  - **Accounting Posting**: Sales and Stock Movements generate journal postings via different adapter bridges (`InventoryAccountingPosterAdapter` vs `SalesPostingOrchestrator`).

---

## 7. Database Architecture

### Legacy Databases
1. `inventory.sqlite` (`products`, `warehouses`, `stock_movement_ledgers`, `inventory_cost_layers`, `product_warehouse_stocks`, `warehouse_accounting_bindings`)
2. `accounting.sqlite` (`accounts`, `journal_entries`, `journal_lines`, `fiscal_years`, `accounting_periods`, `period_closing_records`)
3. `sales.sqlite` (`sales`, `sale_items`, `sale_payments`)
4. `customers.sqlite` (`customers`)
5. `receipts_payments.sqlite` (`financial_transactions`)

### Canonical Database
- `nexabiz.sqlite`: Encrypted SQLite database incorporating unified Drift schemas across all domains.

---

## 8. Current Database → Canonical Database Mapping

| Legacy DB | Table | Current Owner | Target Table | Target Owner | Data Migration Required | Runtime Migration Strategy | Retirement Condition |
| --------- | ----- | ------------- | ------------ | ------------ | ----------------------- | -------------------------- | -------------------- |
| `inventory.sqlite` | `products` | Inventory Module | `products` | `product_master` | Yes | Adapter -> Canonical DB | Full consumer redirection |
| `inventory.sqlite` | `warehouses` | Inventory Module | `warehouses` | `warehouse_management` | Yes | Adapter -> Canonical DB | Full consumer redirection |
| `inventory.sqlite` | `stock_movement_ledgers` | Inventory Module | `stock_movement_ledgers` | `inventory_operations` | Yes | Adapter -> Canonical DB | Direct ledger query deprecation |
| `inventory.sqlite` | `inventory_cost_layers` | Cost Valuation | `inventory_cost_layers` | `inventory_costing` | Yes | Adapter -> Canonical DB | Costing engine consolidation |
| `accounting.sqlite` | `accounts` | Accounting Module | `accounts` | `general_ledger` | Yes | Adapter -> Canonical DB | Chart of accounts unification |
| `accounting.sqlite` | `journal_entries` | Journal Repository | `journal_entries` | `general_ledger` | Yes | Adapter -> Canonical DB | Gateway adoption complete |
| `sales.sqlite` | `sales` | Sales Module | `sales` | `sales_ordering` | Yes | Adapter -> Canonical DB | Sales domain service adoption |
| `customers.sqlite` | `customers` | Customers Module | `customers` | `customers_receivables` | Yes | Adapter -> Canonical DB | Customer subledger consolidation |
| `receipts_payments.sqlite` | `financial_transactions` | Receipts & Payments | `vouchers` | `financial_vouchers` | Yes | Adapter -> Canonical DB | Voucher gateway consolidation |

---

## 9. Architectural Violations

1. **Multi-Database Atomicity Defect (`DocumentPostingOrchestrator.dart:111-128`)**: Cross-database rollback uses manual compensate calls (`_postingCoordinator.unpost`), which can fail midway and leave orphaned journal entries or stock movements.
2. **Direct Tenant Companion Instantiation (`tenant_isolation_security_test.dart:84-114`)**: Legacy test helpers instantiate Drift companions without explicit `companyId` scoping.
3. **Hard-Coded Account Fallbacks (`warehouse_accounting_bindings_table.dart`)**: Fallback strings (e.g. `ACC-1001`) used when semantic account roles are unmapped.
4. **Duplicate Cost Calculation**: `ProductImportPreviewCalculator` duplicates unit cost calculations instead of invoking `InventoryCostCalculatorImpl`.

---

## 10. Duplication Register

1. **Journal Posting Bridges**: `InventoryAccountingPosterAdapter` and `SalesPostingOrchestrator` implement separate posting derivation rules for journal entries.
2. **Stock Valuation Logic**: Unit cost calculation routines exist in both `InventoryCostCalculatorImpl` and import preview helpers.
3. **Tenant Query Enforcers**: Hand-crafted `where((t) => t.companyId.equals(...))` clauses duplicated across repository methods.

---

## 11. Dependency Graph

```text
Identity & Auth
   ↓
Tenant Context
   ↓
Master Data (Products, Warehouses, Customers, Accounts)
   ↓
Inventory Movement Engine
   ↓
Costing Engine
   ↓
Central Accounting Gateway
   ↓
Customer AR Subledger
   ↓
Sales Ordering
   ↓
Treasury & Vouchers
   ↓
Currency / FX
   ↓
Sync Engine
   ↓
Import Engine
   ↓
UI Standardization
```

---

## 12. Migration Risk Register

1. **Cross-Database Transaction Failure (High Risk)**: Multi-database operations failing midway without single `BEGIN/COMMIT`.
2. **Tenant Data Leakage (High Risk)**: Custom raw queries omitting `company_id`.
3. **Journal Entry Unbalance (Medium Risk)**: FX rate discrepancies between document currency and inventory valuation currency.

---

## 13. Proposed Migration Phases

* **PHASE 00 — Architecture Discovery & Baseline**: Complete forensic audit, test run, static analysis, baseline docs generation.
* **PHASE 01 — Identity & Session Scope**: Unify `TenantContext` & `SessionContextPort`.
* **PHASE 02 — Tenant Isolation Structuring**: Enforce structural `company_id` scoping at connection/repository level.
* **PHASE 03 — Master Data Adapter Layer**: Introduce read-only ports for Products, Warehouses, Accounts.
* **PHASE 04 — Inventory Movement Engine**: Consolidate stock ledgers under a single movement authority.
* **PHASE 05 — Central Costing Engine**: Centralize FIFO/LIFO/WAC layer calculations.
* **PHASE 06 — Central Accounting Gateway**: Centralize journal posting and validation.
* **PHASE 07 — Accounts Receivable Subledger**: Connect AR subledger to Accounting Gateway.
* **PHASE 08 — Sales Ordering Consolidation**: Route sales transactions through Movement Engine and Accounting Gateway.
* **PHASE 09 — Treasury & Vouchers**: Centralize cash register accounts and financial vouchers.
* **PHASE 10 — Currency & FX Standardization**: Consolidate exchange rates and base currency resolution.
* **PHASE 11 — Configuration & System Setup**: Standardize first-run setup and system flags.
* **PHASE 12 — Canonical Database Migration (`nexabiz.sqlite`)**: Consolidate legacy databases into single encrypted DB.
* **PHASE 13 — Synchronization Engine Alignment**: Align offline sync queue with canonical database entities.
* **PHASE 14 — Universal Import System**: Implement reusable domain-validated import engine.
* **PHASE 15 — UI System Standardization (`shadcn_flutter`)**: Incrementally modernize UI components.
* **PHASE 16 — Legacy Database Retirement**: Retire per-module SQLite databases after data verification.
* **PHASE 17 — Final Hardening & Verification**: Comprehensive test suite and static analysis compliance.

---

## 14. Recommended First Phase

### Phase 01 / Phase 03 Boundary: `SetupWarehouseLookupPort` & `WarehouseRepositoryAdapter`
* **Why First**: Warehouse lookups are a fundamental master-data dependency required by Inventory, Sales, Setup, and Accounting.
* **Current Blockers**: None.
* **Affected Modules**: `lib/modules/inventory/warehouses/`, `lib/modules/system_setup/`
* **Success Criteria**: 100% read-only lookup boundary verified with zero side-effects.
* **Risks**: Low.

---

## 15. Exact First Phase Scope

1. Define `SetupWarehouseLookupPort` in `lib/modules/inventory/warehouses/domain/ports/`.
2. Implement `WarehouseRepositoryAdapter` adapting current `WarehouseRepository` to `SetupWarehouseLookupPort`.
3. Wire Riverpod provider `setupWarehouseLookupPortProvider`.
4. Validate with isolated unit test `test/setup_warehouse_lookup_port_test.dart`.

---

## 16. Validation Strategy

* **Automated Tests**: Execute `/home/hosam/Downloads/flutter-sdk/flutter/bin/flutter test` ensuring no regressions in existing 613 passing tests.
* **Static Analysis**: Execute `/home/hosam/Downloads/flutter-sdk/flutter/bin/flutter analyze`.
* **Tenant Isolation Test**: Execute `test/tenant_isolation_security_test.dart`.

---

## 17. Exit Criteria

1. 100% test pass rate for all newly introduced adapter ports.
2. Zero new static analysis issues introduced.
3. Complete preservation of existing data and business behavior.

---

## 18. Things That Must NOT Be Changed Yet

* **DO NOT** delete any of the legacy SQLite databases (`inventory.sqlite`, `accounting.sqlite`, etc.).
* **DO NOT** perform a greenfield rewrite of the UI.
* **DO NOT** break existing Riverpod providers relied upon by active screens.
* **DO NOT** modify server sync contracts in `backend-laravel/`.

---

## 19. FINAL ARCHITECTURAL DECISION

```text
WHAT SHOULD WE BUILD?
- An Adapter & Application Boundary Layer routing consumers toward centralized business authorities.

WHAT SHOULD WE KEEP?
- Existing Flutter UI screens, Riverpod state notifiers, domain entities, and Laravel backend sync infrastructure.

WHAT SHOULD WE REFACTOR?
- Multi-database posting bridges (DocumentPostingOrchestrator, SalesPostingOrchestrator) into single Central Accounting Gateway.

WHAT SHOULD WE MIGRATE?
- Per-module SQLite schemas into single canonical encrypted database nexabiz.sqlite.

WHAT SHOULD WE RETIRE?
- Per-module SQLite database connections (after canonical DB migration).

WHERE SHOULD WE START?
- SetupWarehouseLookupPort & Master Data lookup adapters.

WHY?
- It is a zero-risk, read-only dependency required by System Setup, Inventory, and Sales.

WHAT SHOULD PHASE 1 ACTUALLY DO?
- Introduce SetupWarehouseLookupPort and WarehouseRepositoryAdapter with 100% unit test coverage.
```

---

## 20. EXPLICIT STATEMENT

```text
NO PRODUCTION MIGRATION WAS PERFORMED DURING THIS PHASE.
```

---

## 21. FINAL STATUS

```text
ARCHITECTURE PLAN — READY
```
