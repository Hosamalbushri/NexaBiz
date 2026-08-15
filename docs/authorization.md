# Authorization (RBAC)

> Experimental — not production-ready.

## Model

```
User → CompanyUser (membership) → Role → Permissions
```

Authorization always checks **permission codes**, never role names.

Examples: `sales.create`, `customers.view`, `users.manage`, `sync.execute`.

## Enforcement

| Layer | Role |
|-------|------|
| Flutter `PermissionGate` | UX only |
| FastAPI `PermissionChecker` / `require_permissions` | Security |
| Sync push | `sync.execute` + entity operation permission |

## Offline

Flutter stores a permission snapshot for offline UI/mutation gating.
When online, the server re-validates every sync mutation. Revoked
permissions cause `permission_denied` → Flutter `SyncStatus.rejected`
(not silently synced).
