# Sync security

> Experimental — not production-ready.

## Pipeline

```
Repository → Local DB → SyncQueue → SyncManager → SyncEntityHandler
  → RemoteSyncApi → HttpRemoteSyncApi → AuthenticatedHttpClient
  → FastAPI auth → permission check → tenant scope → PostgreSQL
```

SyncManager does **not** implement login/refresh.

## Push checks

1. Valid access token / active session
2. Active user + device + company
3. `sync.execute`
4. Entity permission (`customers.create`, `sales.update`, …)

Failures with `permission_denied` are audited as `sync.authorization_failure`.

## Pull

Requires `sync.execute` or `sync.view`. Results are always filtered by
session company; cursors cannot escape the tenant change stream.
