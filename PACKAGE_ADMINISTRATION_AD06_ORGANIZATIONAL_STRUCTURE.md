# PACKAGE ADMINISTRATION AD-06 — Branches & Organizational Structure

## Executive Summary

Phase AD-06 establishes the canonical organizational structure for NexaBiz ERP while enforcing fundamental separation between administrative organizational units (Branches) and operational/financial domain entities (Company, Warehouse, Cash Register, Accounting Account).

---

## 1. Entity Distinction Matrix

| Entity Type | Domain Owner | Primary Function | Company Scoped | Can Own Inventory? | Can Hold Cash? | Can Post GL Entries? |
| :--- | :--- | :--- | :---: | :---: | :---: | :---: |
| **Company** | System Setup / Auth | Top-level legal entity & tenant isolation boundary | Self | N/A | N/A | Ledger Owner |
| **Branch** | Administration | Administrative division & user assignment scope | Yes | **NO** | **NO** | **NO** |
| **Warehouse** | Inventory | Physical inventory storage & stock movement tracking | Yes | **YES** | No | No |
| **Cash Register** | Cash Registers / POS | Point-of-sale terminal & cash float management | Yes | No | **YES** | No |
| **Accounting Entity** | Accounting | Chart of Accounts node & General Ledger journal target | Yes | No | Indirectly | **YES** |

> [!IMPORTANT]
> **Domain Invariant**: A **Branch** is strictly an administrative grouping entity. It must **never** be used as a hidden substitute for a Warehouse (inventory domain), Cash Register (POS domain), or General Ledger Account (accounting domain).

---

## 2. Structural Specifications

### 2.1 Branch Model & Hierarchy
- `id`: Unique identifier (`br_...`).
- `company_id`: Owning company UUID (enforces multi-tenant isolation).
- `parent_branch_id`: Optional parent branch UUID allowing arbitrary multi-level organizational trees (e.g. Headquarters → Regional Office → Local Branch).
- `name`: Human-readable branch name.
- `code`: Optional short code (e.g., `HQ-01`, `WEST-02`).
- `status`: State flag (`active` / `inactive`).
- `assigned_user_ids`: List of user UUIDs authorized to operate within this branch scope.

### 2.2 Hierarchy Validation Rules
1. **Self-Parent Prevention**: A branch cannot be set as its own parent (`parentBranchId != branchId`).
2. **Circular Reference Prevention**: Setting a parent branch cannot introduce cycles in the hierarchy tree.
3. **Company Alignment**: A child branch must belong to the exact same `company_id` as its parent branch.
4. **Active State Propagation**: Inactivating a parent branch recursively restricts child branch operations.

---

## 3. Implementation Summary

- **Repository**: Updated `AdminRepository` and `AdminBranchSummary` to support `parentBranchId` and `assignedUserIds`.
- **Use Case**: Implemented `ManageAdminBranchesUseCase` with hierarchical cycle detection, self-parenting guard, parent existence check, and user branch assignment audit trail.
- **Audit Logging**: Emits structured administrative events (`branch.created`, `branch.updated`, `branch.status_changed`, `branch_user.assigned`, `branch_user.removed`).

---

## 4. Verification Gate

```text
GATE CERTIFICATION:
[x] Branch entity is strictly administrative and separated from Warehouses, Cash Registers, and Accounting Accounts.
[x] Multi-level parent hierarchy with cycle validation enforced.
[x] Company scoping and authorization filtering verified.
```
