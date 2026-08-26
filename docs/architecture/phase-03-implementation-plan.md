# Phase 3 Implementation Plan — Authentication, Offline Identity & Authorization Hardening

This plan outlines the changes required to implement secure offline authentication, hardened company/user authorization context, session versioning, and unified security validation.

---

## 1. Objectives

1. **AuthorizationContext**: Centralize runtime authorization state (userId, companyId, permissions, roleId, entitlement, authenticationMode, offlineSince, authorizationExpiresAt, deviceId).
2. **OfflineAuthorizationStore Scoping**: Store snapshots under `offline_auth_${companyId}_${userId}` in encrypted storage.
3. **OfflineLoginPolicy**: Enforce strict verification of user status, membership, device binding, and snapshot expiration.
4. **User & Company Switch Reactivity**: Ensure complete state invalidation and cache purging.
5. **Entitlement & Permission Matrix**: Ensure both entitlement capability AND user permission must be active for sensitive operations (e.g. `sync`).

---

## 2. Proposed Code Changes

### A. Authorization Context Domain
- **[`lib/core/auth/domain/entities/authorization_context.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/domain/entities/authorization_context.dart)**: Define the unified runtime representation of effective permissions, active company, and company entitlement.

### B. Hardened Offline Store
- **[`lib/modules/authentication/data/offline_authorization_store.dart`](file:///home/hosam/StudioProjects/untitled2/lib/modules/authentication/data/offline_authorization_store.dart)**: Update `_buildKey` to scope snapshots by `offline_auth_${companyId}_${userId}` instead of flat keys.

### C. Offline Login Policy
- **[`lib/core/auth/domain/services/offline_login_policy.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/domain/services/offline_login_policy.dart)**: Create policy engine verifying expiration (14-day limit), device ID matching, and session versioning.

### D. Provider Reactivity & Switching
- **[`lib/core/auth/presentation/providers/auth_context_providers.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/auth/presentation/providers/auth_context_providers.dart)**: Expose reactive `authorizationContextProvider` which automatically clears state on switch/logout events.

### E. Sync Integration Hardening
- **[`lib/core/sync/sync_manager.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_manager.dart)**: Block synchronization unless the `AuthorizationContext` is authenticated, active, possesses `permission.sync`, and active company entitlement has `EntitlementCapability.sync`.

---

## 3. Test & Verification Plan

- Create `test/authentication_offline_security_test.dart` covering all 20 security scenarios.
- Verify zero regressions by running full test suite (82 tests).
