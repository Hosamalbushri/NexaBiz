# Phase 3 Audit — Authentication & Offline Authorization

- **Status**: `AUDITED`
- **Date**: 2026-08-25
- **Author**: Senior Software Architect

---

## 1. Executive Summary

This audit evaluates the current state of authentication, local auth store, offline session caching, device binding, and Laravel (Python FastAPI) backend identity systems in NexaBiz. The goal is to detect vulnerabilities, weaknesses, and stale session risks, and design a hardened model for local/remote authorization.

---

## 2. Current Authentication & Flow Analysis

### A. Online Login Flow
1. User enters email, password, and URL.
2. App validates URL and makes a `POST /api/v1/auth/login` request.
3. Server returns a JSON response containing the authenticated user, role, list of companies, and permission set.
4. Access token and refresh token are written to secure storage (`FlutterSecureStorage`).
5. Session snapshot is stored in `LocalAuthStore` (encrypted Hive).

### B. Offline Login Flow
1. App reads cached credentials/salted hashes in `LocalAuthStore`.
2. Validates password hash matching user input.
3. Restores user session and permissions from the cached `AuthSessionSnapshot`.
4. Renders the application UI.

### C. Logout Flow
1. Clears stored session snapshot from `LocalAuthStore`.
2. Clears OAuth tokens from `FlutterSecureStorage`.
3. Navigates back to the login screen.

### D. Company Switching Flow
1. Re-routes request to `/api/v1/auth/switch-company` online.
2. Updates `currentCompanyId` in `AuthSessionSnapshot`.
3. Reloads company-scoped permissions and saves new snapshot.
4. Offline: Loads company permissions from local user record inside `LocalAuthStore`.

---

## 3. Token & Permission Persistence

- **JWT Tokens**: Stored in `secure_token_storage.dart` using `FlutterSecureStorage`.
- **Session Cache**: Stored in `local_auth_store.dart` under Hive key `session_snapshot` inside the `local_auth_encrypted` box.
- **Offline Authorization Snapshots**: Stored in `OfflineAuthorizationStore` using Hive or secure storage, isolated by `serverBaseUrl`, `companyId`, and `userId`.

---

## 4. Security Weaknesses & Risks

1. **Global Master Session Cache**:
   - `AuthSessionSnapshot` is cached globally under `session_snapshot`. It does not strictly separate session cache by `userId` and `companyId` for concurrent/consecutive offline logins, creating risks of permission leakage if a user switch is performed offline.
2. **Device Identity Lack of Binding**:
   - Local permission snapshots are saved per `(serverBaseUrl, companyId, userId)` but are not bound to a cryptographically verified `deviceId` on the client side, allowing potential snapshot replication or spoofing across devices.
3. **Session Revocation & Versioning**:
   - No runtime `sessionVersion` or `authorizationVersion` check exists to invalidate outdated permission snapshots upon client reconnection, creating stale permission risks.
4. **Separation of Entitlement vs Permissions**:
   - Entitlements (e.g. Free/Premium) and user roles/permissions must remain separate. Entitlement gates capabilities (e.g., `sync`), while permissions gate operations (e.g., `sales.create`). The integration of sync must explicitly require both.
5. **Laravel/Python Backend Authorization**:
   - Laravel references are aligned to the Python FastAPI backend (`app/auth/authorization.py`). We must ensure the backend derives `company_id` and permissions authoritative state from the authenticated JWT token rather than trusting request parameters.

---

## 5. Security Recommendations
- Introduce a reactive `AuthorizationContext` containing `userId`, `companyId`, `permissions`, `roleId`, `entitlement`, `authenticationMode`, `offlineSince`, `authorizationExpiresAt`, and `deviceId`.
- Harden `OfflineAuthorizationStore` to store snapshots scoped by `userId + companyId` using the key format `offline_auth_<companyId>_<userId>`.
- Enforce strict `OfflineLoginPolicy` validating user existence, device authorization, session expiration, and tenant context alignment.
- Reset/clear in-memory authorization states and Riverpod providers completely on logout or switch events.
