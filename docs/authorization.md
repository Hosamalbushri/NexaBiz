# Authorization (RBAC)

> Experimental — offline-first domain checks + UX gates; sync backend still experimental.

## Model

```
User → CompanyUser (membership) → Role → Permissions
```

Authorization always checks **permission codes**, never role names.

Examples: `sales.create`, `customers.view`, `users.manage`, `sync.execute`.

## Enforcement

| Layer | Role |
|-------|------|
| Flutter `PermissionGate` / `requiredAnyPermissions` | UX only (menu + actions) |
| Flutter use cases via `PermissionGuard` | **Offline mutation boundary** (P0 financial actions) |
| FastAPI `PermissionChecker` / `require_permissions` | Security for sync/admin APIs |
| Sync push | `sync.execute` + entity operation permission |
| Last-admin guard | Server rejects deactivating the last active super admin |

Critical mutate use cases call `permissionGuardProvider` → `CallbackPermissionGuard`
backed by the session permission snapshot (`authStateProvider`). Missing grants
throw `PermissionDeniedException` before repositories run.

Covered today (domain): journal post/void, account soft-delete, fiscal year
create / open / close / reopen period, sale create/confirm/cancel, R&P
create/post/cancel.

## Sync enable + auth

Synchronization requires a remote login. If the session expires, sync preference
and the **remote permission snapshot** stay in place so the user keeps the same
UI access offline until they renew credentials. Explicitly disabling sync clears
the remote session and restores the local full-admin snapshot.

## Offline

Flutter stores a permission snapshot for offline UI/mutation gating.
When online, the server re-validates every sync mutation. Revoked
permissions cause `permission_denied` → Flutter `SyncStatus.rejected`
(not silently synced).

Administration → Users requires an authenticated online sync session.
