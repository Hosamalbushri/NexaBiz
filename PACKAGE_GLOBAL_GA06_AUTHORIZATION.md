# PACKAGE_GLOBAL_GA06_AUTHORIZATION.md — Global Authentication & Authorization Audit

## Executive Summary
This document provides the complete forensic audit of the end-to-end authorization chain across NexaBiz ERP. It verifies login workflow, JWT token/session management, RBAC permission resolution, permission guards, route guards, offline authorization snapshots, server-side API policies, sync payload authorization, and export controls. Client-side checks act purely as UX controls; server-side policies independently reject any unauthorized operation.

---

## 1. End-to-End Authorization Architecture

```
[User Login Credentials]
       │
       ▼ (JwtTokenService / AuthController)
[JWT Bearer Token + Assigned RBAC Roles]
       │
       ▼ (Local Cryptographic Snapshot)
[Offline Authorization Snapshot]
       │
       ▼ (PermissionGuard.requireAny / requireAll)
[Domain Operation Authorization]
       │
       ▼ (Laravel AuthenticateApi Middleware & Policies)
[Server-Side API Authorization]
```

---

## 2. Comprehensive Security Boundary Verification

| Authorization Layer | Guard Implementation | Verification Scope | Status |
|---|---|---|---|
| Login & Auth Session | `JwtTokenService` & `LocalBruteForceProtector` | Rate limiting & token signing validation | **ENFORCED** |
| Route Access | `CompanyInitializationRouteGuard` & GoRouter Guards | Blocks unauthorized route navigation | **ENFORCED** |
| Module Operations | `PermissionGuard` in Use Cases & Posting Coordinators | Explicit check (`InventoryPermissions.receiptsPost`, `issuesPost`, etc.) | **ENFORCED** |
| Backend API Control | Laravel Middleware `AuthenticateApi` & Authorization Policies | Independent server-side 403 response on missing permission | **ENFORCED** |
| Offline Security | `OfflineAuthorizationSnapshot` & Secure Storage | Validates offline capabilities based on last authenticated snapshot | **ENFORCED** |
| Sync Authorization | Backend `SyncController` Auth Context | Rejects push/pull operations if user lacks sync permission | **ENFORCED** |
| Export Controls | `ProductExcelImportIsolate` & Export Action Guards | Gated behind export permission flags | **ENFORCED** |

---

## 3. Critical Security Invariant Assertions

1. **Client Control Non-Reliance**: Hidden UI buttons or omitted navigation links do NOT form the final security boundary. Direct REST calls without bearer tokens return HTTP 401 Unauthorized; calls with insufficient RBAC roles return HTTP 403 Forbidden.
2. **Offline Tamper Resistance**: Offline credentials and authorization snapshots stored in Flutter Secure Storage use AES encryption and fail closed if corrupted.

---

## 4. Test Matrix & Verification Results

- **Verified via**: `AuthRbacTest.php` (Laravel), `authentication_offline_security_test.dart` (Flutter).
- **Test Scenarios**:
  - Authorized user performs posting operation: **SUCCESS**.
  - Unauthorized user attempts posting operation: **BLOCKED (PermissionDeniedException / HTTP 403)**.
  - Direct route entry to administrative setup without setup permission: **REDIRECTED TO HOME**.
  - Direct sync API invocation with expired token: **HTTP 401**.

**GA-06 Gate Status**: **PASS**
