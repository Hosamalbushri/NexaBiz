# 10 — ARCHITECTURE & MODULE BOUNDARIES

## 1. Architectural Model
NexaBiz strictly adheres to **Clean Modular Architecture** integrated with **Hexagonal Architecture (Ports & Adapters)**.

The overall architectural hierarchy MUST strictly enforce unidirectionality:

```text
Presentation
      ↓
Application
      ↓
Domain
      ↑
Ports
      ↑
Adapters / Infrastructure
```

---

## 2. Layer Responsibilities
1. **Domain Layer**:
   * Contains pure business entities, value objects, domain events, domain error definitions, and interface contracts (ports).
   * MUST NOT depend on Flutter, Riverpod, Drift, Hive, GoRouter, HTTP, or any external framework/infrastructure package.
   * Holds pure business rules and invariants.
2. **Application Layer**:
   * Contains use cases, domain event handlers, transaction orchestrators, and application service interfaces.
   * Coordinates business flows across domain entities and ports.
   * MUST NOT perform direct UI rendering, direct SQL execution, or HTTP handling.
3. **Ports Layer**:
   * Defines abstract interface specifications for infrastructure dependencies (e.g., repositories, storage, currency engines, network adapters, sync engines).
   * Owned by the Domain/Application layers to enable dependency inversion.
4. **Adapters & Infrastructure Layer**:
   * Implements Ports using specific technologies (Drift SQLite, SQLCipher, Hive, FlutterSecureStorage, Laravel REST API clients).
   * Handles database persistence, network communication, encryption, and local device hardware integration.
5. **Presentation Layer**:
   * Contains Flutter widgets (`shadcn_flutter`), Riverpod UI controllers/providers, GoRouter route definitions, form validation controllers, and view state models.
   * MUST NOT execute domain calculations, SQL queries, direct GL posting, or business transaction orchestration.

---

## 3. Module Boundaries & Ownership
NexaBiz comprises the following bounded business modules:
`accounting`, `administration`, `authentication`, `app_lock`, `cash_registers`, `customers`, `inventory`, `purchases`, `receipts_payments`, `reports`, `sales`, `sync`, `system_setup`, `currency`, `import`.

### Boundary Governance
1. **Strict Module Isolation**: Direct concrete imports across module boundaries are STRICTLY FORBIDDEN (e.g., `sales` MUST NOT directly import concrete classes from `inventory` or `accounting`).
2. **Inter-Module Communication**: Modules MUST communicate exclusively through:
   * Public module Ports / Interfaces defined in abstract domain contracts.
   * Published Domain Events dispatched via the application event bus.
   * Shared primitive Value Objects (e.g., `TenantId`, `Money`, `CurrencyCode`).
3. **Cross-Domain Boundaries**:
   * **Accounting Boundary**: Operational modules (Sales, Purchases, Cash Registers) emit posting intents. They do NOT import accounting repositories or directly construct General Ledger rows.
   * **Inventory Boundary**: Stock movements, receipts, issues, and cost determination are owned by `inventory`. Financial valuation and GL posting are routed via `accounting` interfaces.
   * **Customer / Supplier Boundary**: Master party data is managed by `customers` / `administration`. Financial balances are calculated by `accounting` subledgers.
   * **Currency Boundary**: All monetary operations consume the centralized `currency` exchange engine port governed by `60-currency.md`.

---

## 4. Cross-Cutting Technical Authorities
1. **State Management**: Managed via **Riverpod**. Providers in presentation MUST only expose presentation state or invoke application use cases. Providers MUST NOT store master business truth or execute SQL queries.
2. **Routing**: Managed via **GoRouter**. Routes MUST incorporate tenant guard policies and authentication checks.
3. **Offline-First & Sync**: Operations commit to the local encrypted SQLite database first. Synchronization with the Laravel backend is managed asynchronously via `sync` module handlers without blocking local transactional commits.

---

## 5. Prohibited Architectural Patterns
The following shortcuts and anti-patterns are STRICTLY FORBIDDEN:
* **Concrete Cross-Module Imports**: Direct coupling between business module implementations.
* **UI Business Authority**: Embedding business logic, tax calculations, or GL posting within Flutter widgets or UI controllers.
* **Infrastructure Business Authority**: Implementing business rules, pricing algorithms, or validation inside SQL triggers, raw database queries, or network adapters.
* **Repository-Owned Global Transactions**: Repositories managing cross-domain database transactions directly instead of an application transaction orchestrator.
* **Provider-Owned Business Truth**: Riverpod state providers acting as the single source of business truth instead of persisting to the database.
* **Accounting Ownership of Operational Truth**: Accounting modules creating or modifying sales orders, purchase invoices, or stock movement documents.

---

## 6. Architectural Migration & Call-Graph Verification
1. **Production Path Convergence**: Whenever a new hexagonal port or canonical service is introduced, all production entry points (UI buttons, API handlers, background tasks) MUST be updated to route through it.
2. **Call-Graph Verification**: Code review and static analysis MUST confirm that no legacy architectural bypasses remain reachable in the production call graph.
