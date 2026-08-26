# Change Log - NexaBiz Architecture

All notable changes to the architecture design, database isolation, subscription entitlements, authentication, and security boundaries will be documented in this file.

---

## [2026-08-25]
### Phase 4 — Offline Data Access Security, Session Isolation & Authorization Enforcement
- **Files Created**:
  - [`lib/core/auth/domain/services/local_access_policy.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/domain/services/local_access_policy.dart): Centralized access validation domain-level guard.
  - [`lib/core/logging/security_logger.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/logging/security_logger.dart): Cleansed structured security event logging utility.
  - [`test/phase4_offline_data_access_security_test.dart`](file:///home/hosam/StudioProjects/untitled2/test/phase4_offline_data_access_security_test.dart): Test suite verifying 35 offline security verification scenarios.
- **Files Modified**:
  - [`lib/core/sync/sync_operation.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_operation.dart): Added `companyId` and `deviceId` metadata parameters.
  - [`lib/core/sync/sync_operation_adapter.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_operation_adapter.dart): Serializes fields `12` and `13`.
  - [`lib/core/sync/sync_queue.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_queue.dart): Filters `peekReady` by active companyId, validates tenant on enqueue.
  - [`lib/core/sync/sync_providers.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_providers.dart): Propagates active companyId and deviceId to SyncQueue/SyncManager.
  - [`lib/core/sync/sync_manager.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_manager.dart): Quarantines mismatched company operations.
- **Security Invariants Verified**:
  - Verified User A cannot access Company B data offline.
  - Verified company switch updates tenant boundaries and forces Riverpod cache cleanups.
  - Verified sync operations verify both permission and entitlement.
  - Verified sync queue is strictly scoped by companyId, preventing cross-tenant upload leakages.

### Phase 3 — Authentication, Offline Identity & Authorization Hardening
- **Files Created**:
  - [`lib/core/auth/domain/entities/authorization_context.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/domain/entities/authorization_context.dart): Centralized effective runtime authorization state.
  - [`lib/core/auth/domain/services/offline_login_policy.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/domain/services/offline_login_policy.dart): Strict policy evaluating offline logins against cached snapshots, membership, and grace policy.
  - [`lib/core/auth/presentation/providers/auth_context_providers.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/presentation/providers/auth_context_providers.dart): Riverpod provider for reactive context switches.
  - [`test/authentication_offline_security_test.dart`](file:///home/hosam/StudioProjects/untitled2/test/authentication_offline_security_test.dart): Fully-comprehensive offline authentication/authorization test suite containing 21 security test cases.
- **Files Modified**:
  - [`lib/modules/authentication/data/offline_authorization_store.dart`](file:///home/hosam/StudioProjects/untitled2/lib/modules/authentication/data/offline_authorization_store.dart): Key hashing and safe legacy snapshot migrations.
  - [`lib/modules/authentication/data/local_auth_repository.dart`](file:///home/hosam/StudioProjects/untitled2/lib/modules/authentication/data/local_auth_repository.dart): Integrated `OfflineLoginPolicy` evaluation and `EntitlementRepository` checks.
  - [`lib/modules/authentication/presentation/providers/auth_providers.dart`](file:///home/hosam/StudioProjects/untitled2/lib/modules/authentication/presentation/providers/auth_providers.dart): Added entitlement provider dependencies.
- **Security Invariants Verified**:
  - Verified User B cannot inherit User A's session context or permissions.
  - Verified invalid passwords/inactive status block offline login.
  - Verified expired snapshots (grace period exceeding 14 days) are blocked.
  - Verified sync capability requires both entitlement and permission codes.
