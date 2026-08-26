# Phase 3 Security Flow Diagrams

This document contains visual representations of security processes and transitions in the NexaBiz Business Platform.

---

## 1. Online Login Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Operator
    participant UI as Login Page
    participant Controller as AuthController
    participant Repo as AuthRepositoryImpl
    participant Laravel as Laravel Backend
    participant Storage as FlutterSecureStorage

    User->>UI: Enter Email & Password
    UI->>Controller: login(email, password)
    Controller->>Repo: login(email, password, deviceId, ...)
    Repo->>Laravel: POST /api/v1/auth/login
    Note over Laravel: Authenticate credentials, load company membership & permissions
    Laravel-->>Repo: Return User, Companies, Permissions & JWT Session
    Repo->>Storage: Save Access & Refresh Tokens
    Repo->>Repo: Create and Save OfflineAuthorizationSnapshot
    Repo->>Controller: Emit AuthSessionSnapshot
    Controller-->>UI: Navigate to Dashboard
```

---

## 2. Offline Login Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Operator
    participant UI as Login Page
    participant Controller as AuthController
    participant LocalRepo as LocalAuthRepository
    participant Store as OfflineAuthorizationStore
    participant Policy as OfflineLoginPolicy

    User->>UI: Enter Email & Password
    UI->>Controller: loginLocal(email, password)
    Controller->>LocalRepo: login(email, password, ...)
    LocalRepo->>LocalRepo: Verify local salted password hash in Hive
    alt Local Password Valid
        LocalRepo->>Store: loadSnapshot(serverBaseUrl, companyId, userId)
        Store-->>LocalRepo: Return OfflineAuthorizationSnapshot
        LocalRepo->>Policy: evaluate(snapshot, requestedUserId, requestedCompanyId, entitlement, ...)
        alt Policy Result: Allowed
            Policy-->>LocalRepo: OfflineLoginAllowed
            LocalRepo->>Controller: Emit AuthSessionSnapshot (Restored Permissions)
            Controller-->>UI: Navigate to Dashboard
        else Policy Result: Expired / Denied / DeviceMismatch
            Policy-->>LocalRepo: Deny Result
            LocalRepo->>Controller: Emit AuthSessionSnapshot (Empty Permissions)
            Controller-->>UI: Show Failure Gate / Upgrade Prompts
        end
    else Local Password Invalid
        LocalRepo-->>Controller: Throw AuthenticationFailure
        Controller-->>UI: Show Invalid Credentials
    end
```

---

## 3. User Switching Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Operator
    participant Controller as AuthController
    participant Providers as Riverpod Provider Container
    participant Store as OfflineAuthorizationStore

    User->>Controller: logout()
    Controller->>Store: deleteAllSnapshotsForUser(userId)
    Note over Controller: Clear AuthSessionSnapshot & AuthorizationContext
    Controller->>Providers: Invalidate authStateProvider & permissionGuardProvider
    Note over Providers: All downstream repository and page providers reset cleanly
    Controller-->>User: Show login screen
```

---

## 4. Company Switching Flow

```mermaid
sequenceDiagram
    autonumber
    actor User as Operator
    participant Controller as AuthController
    participant Remote as AuthRepositoryImpl
    participant Providers as Riverpod Provider Container

    User->>Controller: switchCompany(companyId)
    Controller->>Remote: switchCompany(companyId)
    Remote->>Remote: Fetch new scoped permissions & switch company
    Remote-->>Controller: Return next snapshot
    Controller->>Providers: Invalidate currentCompanyIdProvider & currentEntitlementProvider
    Note over Providers: Rebuild AuthorizationContext with new company entitlements & permissions
    Controller-->>User: Refresh Dashboard
```

---

## 5. Sync Authorization Flow

```mermaid
sequenceDiagram
    autonumber
    participant Sync as SyncManager
    participant Providers as Riverpod Provider Container
    participant Context as AuthorizationContext

    Sync->>Sync: triggerSync()
    Sync->>Providers: Watch authorizationContextProvider
    Providers-->>Sync: Return AuthorizationContext
    Sync->>Context: hasAuthorizedCapability(permission: 'sync.execute', capability: EntitlementCapability.sync)
    alt Context returns true
        Sync->>Sync: Proceed with Sync HTTP Pass
    else Context returns false
        Sync->>Sync: Skip Sync / Fail Closed
    end
```

---

## 6. Entitlement + Permission Evaluation

```mermaid
graph TD
    Perm[User holds permission 'sync.execute'?] -->|Yes| Ent[Company holds sync entitlement?]
    Perm -->|No| Deny[Deny Sync Operation]
    Ent -->|Yes| Mode{Auth mode?}
    Ent -->|No| Deny
    Mode -->|Local| Deny
    Mode -->|Sync/Online| Allow[Allow Sync Operation]
```
