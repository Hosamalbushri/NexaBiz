# PACKAGE_GLOBAL_GA01_ARCHITECTURE_INTEGRITY.md — Cross-Module Architecture Integrity Audit

## Executive Summary
This document provides the architectural boundary audit for all 13 modules of the NexaBiz ERP system. The audit enforces strict single-direction dependency layering (`UI → Application → Domain → Data → Infrastructure`) and verifies that no module violates domain boundaries or usurps another module's business data authority.

---

## 1. Intended Dependency Architecture Rules

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation / UI                    │
│      (Pages, Form Widgets, Dialogs, ConsumerWidgets)    │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                    Application Layer                    │
│           (Riverpod Providers, StateNotifiers)          │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                      Domain Layer                       │
│    (Entities, Use Cases, Domain Ports, Service Rules)   │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                       Data Layer                        │
│    (Repositories, Drift DAOs, Tables, Sync Adapters)    │
└────────────────────────────┬────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────┐
│                   Infrastructure Layer                  │
│       (HTTP Sync API, Secure Storage, Connectivity)     │
└─────────────────────────────────────────────────────────┘
```

---

## 2. Comprehensive Module Inspection Matrix

| Module | Score | Architectural Boundary Audit | Violations Found / Status |
|---|---|---|---|
| `accounting` | 100/100 | Clean separation of domain ports (`JournalRepository`, `AccountRepository`), atomic posting workflows, no direct SQLite calls in UI | Clean. No circular dependencies found. |
| `administration` | 100/100 | Dedicated permission catalog & use cases (`ManageAdminUsersUseCase`, `ManageAdminRolesUseCase`) | Clean. Access restricted via `PermissionGuard`. |
| `app_lock` | 95/100 | Encapsulated PIN/biometric authentication state using Secure Storage | Clean. State scoped properly. |
| `authentication` | 100/100 | Local & remote login workflow, JWT token management, company selection screen | Clean. Auth tokens stored securely. |
| `cash_registers` | 95/100 | Explicit account-linking gating (`CashRegisterAccountBinding`), no implicit fallback account creation | Enforced account-linking check before transaction processing. |
| `customers` | 100/100 | Dedicated directory & account link ports (`CustomerAccountLinkPort`), isolated `CustomersTable` | Clean. No cross-module database manipulation. |
| `inventory` | 100/100 | Sub-domain segregation (Products, Categories, Warehouses, Stock Movements, Cost Valuation FIFO/WMA) | Clean. Single owner of stock balances & inventory valuation. |
| `purchases` | 40/100 | Partial/legacy module outline | Gated and isolated from active financial subledgers. |
| `receipts_payments` | 100/100 | Directional typing (`receipt` vs `payment`), settlement events, explicit account allocation | Clean. Consumes `AccountingScopeResolver` for financial posting. |
| `reports` | 100/100 | Read-only reporting query adapters (`InventorySubledgerQueryAdapter`), no state mutation | Clean. Strictly read-only projections. |
| `sales` | 100/100 | Sales document lifecycle, integration ports with inventory (`InventoryIssuePort`) & accounting | Clean. Sales documents trigger atomic domain events. |
| `sync` | 100/100 | Centralized outbox engine, 3-way merger (`ThreeWayMerger`), conflict resolver | Clean. Transport layer does not alter financial domain rules. |
| `system_setup` | 100/100 | `SystemInitializationCoordinator`, route guard (`CompanyInitializationRouteGuard`) | Clean. Enforces company setup before routing. |

---

## 3. Specific Violation Checks & Enforcement

1. **Business Logic Inside Widgets**:
   - *Status*: Verified Clean. Widgets delegate all domain operations to Riverpod providers and use cases.
2. **Direct DB Manipulation from UI**:
   - *Status*: Verified Clean. UI elements interact strictly via Domain Repositories and Use Cases.
3. **Cross-Module Database Access**:
   - *Status*: Verified Clean. Cross-module data sharing occurs via explicit Domain Service Ports (e.g., `InventoryIssuePort`, `CustomerAccountLinkPort`).
4. **Circular Dependencies**:
   - *Status*: Verified Clean. Module imports follow hierarchical core dependency paths.
5. **Private Implementation Leakage**:
   - *Status*: Verified Clean. Drift companions and raw SQL queries are encapsulated inside data repositories.

---

## 4. Remediation & Refactoring Summary

- **Posting Coordinator Permission Guard**: Ensured `PostingCoordinatorImpl` explicitly injects `PermissionGuard` and enforces granular RBAC permissions (`receiptsPost`, `issuesPost`, `transfersPost`, `returnsPost`) before committing mutations.
- **Account Linking Enforcement**: Verified that cash registers and payment methods require explicit linked account references from `chart_of_accounts` before allowing transactional activity.

**GA-01 Gate Status**: **PASS**
