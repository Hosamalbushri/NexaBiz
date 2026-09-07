# PACKAGE ADMINISTRATION AD-08 — User ↔ Role Assignment

## Executive Summary

Phase AD-08 implements secure User-Role Assignment logic with multi-role union effective permission resolution, company scoping, and absolute anti-privilege-escalation guards.

---

## 1. Role Assignment Principles & Delegation Rules

1. **Privilege Escalation Prevention (Anti-Escalation Invariant)**:
   - Administrators **cannot** create or update a role with permission codes that they do not personally hold (`_validateDelegablePermissions`).
   - Administrators **cannot** assign a role to any user if that role contains permissions exceeding the administrator's own authorized set.
   - Super-Admin override (`isSuperAdmin == true`) is required to grant system-wide super permissions (`*`).

2. **Multi-Role Union Resolution**:
   - When a user is assigned multiple roles, effective permissions are calculated as the strict union of all granted permission sets across active roles (`calculateEffectivePermissions(roleIds)`).
   - Denial or restriction policies explicitly override broad grants when explicit deny flags exist.

3. **Stale Permission Cache Invalidation**:
   - Assigning or removing a user role automatically invalidates local permission caches, updates Riverpod/Bloc authorization providers, and invalidates active session router guards.
   - Backend APIs enforce role updates on the subsequent API request via JWT claim refresh / token revalidation.

---

## 2. Delegation Verification Matrix

| Actor Role | Held Permissions | Target Role Permissions | Attempted Action | Result |
| :--- | :--- | :--- | :--- | :--- |
| **Sales Manager** | `sales.view`, `sales.create` | `sales.view`, `sales.create` | Assign Role | `200 Success` |
| **Sales Manager** | `sales.view`, `sales.create` | `sales.view`, `accounting.post` | Assign Role | `ValidationFailure` — Privilege escalation denied (`accounting.post`) |
| **Branch Admin** | `branches.manage` | `platform.users.manage` | Create Role | `ValidationFailure` — Delegation guard rejected unauthorized permission |
| **Super Admin** | `*` (All permissions) | Any permission set | Assign/Create | `200 Success` |

---

## 3. Implementation Summary

- **Anti-Escalation Engine**: Implemented `_validateDelegablePermissions` in `ManageAdminRolesUseCase` checking actor permissions before role creation, modification, or assignment.
- **Multi-Role Effective Calculation**: Implemented `calculateEffectivePermissions(roleIds)` aggregating role permissions into a unified active permission set.
- **Audit Logging**: Logs `role.created`, `role.updated`, `role.deleted`, `user_role.assigned`, and `user_role.removed` administrative events.

---

## 4. Verification Gate

```text
GATE CERTIFICATION:
[x] Privilege escalation through role creation or assignment is strictly impossible.
[x] Multi-role union effective permission calculation verified.
[x] Real-time permission cache invalidation and router guard updates enforced.
```
