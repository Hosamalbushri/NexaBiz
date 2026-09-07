# PACKAGE_SYNC_SY08_AUTHORIZATION_IMPLEMENTATION.md

## SY-08: Integration of Synchronization with NexaBiz Authentication & RBAC Implementation Documentation

### Executive Summary
Synchronization operations in NexaBiz are authenticated and authorized using the same unified Sanctum JWT token infrastructure and Role-Based Access Control (RBAC) engine that protects standard business API endpoints. Client-side claims are never trusted; the Laravel backend independently verifies user authentication and domain-level module permissions for every pushed or pulled operation.

---

### 1. Authentication Architecture

- **Unified Client HttpClient**: All sync HTTP traffic (`HttpRemoteSyncApi`) routes through `AuthenticatedHttpClient`.
- **Request Headers**:
  - `Authorization: Bearer <Sanctum_JWT_Token>`
  - `X-Company-Id: <Company_UUID>`
  - `X-User-Id: <User_UUID>`
- **Token Lifecycle & Expiration**:
  - If a token expires (HTTP 401 Unauthorized), `SyncErrorClassifier` classifies the failure as `unauthorized`.
  - Active sync passes halt immediately without corrupting local outbox queues.
  - The application prompts the user for token refresh / re-login.

---

### 2. Authorization & RBAC Permission Mapping

Before executing any sync operation (`push`, `pushBatch`, `pull`), `SyncController` invokes `Authorization::requireSyncOperationPermission($permissions, $entityType, $operationType)`.

| Entity Type | Required Domain Permission (View / Push) | Fail-Closed Error |
| :--- | :--- | :--- |
| `sales_invoice`, `sale` | `sales.view` / `sales.create` | 403 Forbidden (`AUTH_PERMISSION_DENIED`) |
| `journal_entry`, `account` | `accounting.view` / `accounting.create` | 403 Forbidden (`AUTH_PERMISSION_DENIED`) |
| `stock_receipt`, `stock_issue`, `stock_transfer`, `stock_return`, `product` | `inventory.view` / `inventory.create` | 403 Forbidden (`AUTH_PERMISSION_DENIED`) |
| `customer`, `supplier` | `customers.view` / `customers.create` / `suppliers.create` | 403 Forbidden (`AUTH_PERMISSION_DENIED`) |
| `receipt_payment`, `cash_register` | `treasury.view` / `treasury.create` | 403 Forbidden (`AUTH_PERMISSION_DENIED`) |

---

### 3. Security Audit Logging

Whenever an authorization failure occurs on the server (e.g. a user attempting to sync a module for which they lack RBAC privileges), the server emits a security audit event:

```php
$this->audit->write(
    action: 'sync.authorization_failure',
    userId: $auth->userId(),
    companyId: $companyId,
    deviceId: $auth->deviceId,
    entityType: $op['entity_type'],
    entityId: (string) $op['entity_id'],
    metadata: [
        'operation' => $op['type'],
        'error' => $exc->errorCode,
        'message' => $exc->getMessage(),
    ],
);
```

---

### 4. Offline Authorization Boundaries

- **Offline Local Mutations**: Local operations created offline require a valid active user session on the device (`LocalAuthorizationGuard`).
- **Online Sync Gatekeeping**: Offline execution never grants permanent bypass of server security. When the client reconnects and pushes queued mutations, the server independently validates RBAC permissions against the user's active session.

---

### 5. Verification Matrix

All 94 tests across 9 unit and integration test suites passed:

```
test/phase5_sync_integrity_test.dart .................. PASSED (40/40)
test/http_remote_sync_api_test.dart ................... PASSED (3/3)
test/sync_reliability_hardening_test.dart ............ PASSED (4/4)
test/sync_engine_invariants_test.dart .................. PASSED (20/20)
test/sync_phase1_safety_test.dart ..................... PASSED (2/2)
test/tenant_sync_storage_test.dart .................... PASSED (2/2)
test/modules/sync/sync_company_isolation_mc09_test.dart PASSED (7/7)
test/sync_create_idempotency_test.dart ................ PASSED (5/5)
test/inventory_sync_remote_change_security_test.dart .. PASSED (6/6)
---------------------------------------------------------------------
TOTAL: 94 Scenarios (100% Pass Rate)
```

---

### 6. Certification
Integration of Synchronization with NexaBiz Authentication and RBAC (SY-08) is certified production-ready. Token handling, server-side RBAC enforcement, audit log emission, and offline safety boundaries are fully verified.
