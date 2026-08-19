# Authentication

> Experimental — offline-first local session by default; remote JWT required to enable sync.

## Behaviour

### Without synchronization

On app start:

1. Seed local admin + company in Hive (if missing).
2. Restore a **previously saved** local session, or show **Sign in**.
3. There is **no silent auto-login** and credentials are **never prefilled**.
4. After sign-in, if the local password is still the bootstrap default, the
   app **blocks** until a new password is set (`/change-password`).
5. Then System Setup (if incomplete) or Dashboard.

First-install local credentials (must be changed before the app is usable):

| Field | Value |
|-------|--------|
| Email | `admin@local` |
| Password | `admin123` |

These values exist only to bootstrap an empty local store. They are never
prefilled in UI fields. Signing in with the default password forces a password
change; the default value is rejected as the new password.

### Enabling synchronization

1. Settings → Data & Sync → set Server URL (HTTPS) and token
2. Toggle **Enable synchronization**
3. Authentication page opens (`POST /api/v1/auth/login`)
4. On success: tokens stored securely, sync enabled, initial sync runs
5. On failure: sync remains disabled; no tokens stored

Compile-time sync defaults are **fail-closed** (`SYNC_API_ENABLED=false`, empty
URL/token). LAN HTTP requires explicit
`--dart-define=SYNC_API_ALLOW_INSECURE_HTTP=true`.

Seeded backend admin (development):

| Field | Value |
|-------|--------|
| Email | `admin@example.com` |
| Password | `ChangeMeAdmin!123` |

Demo sales user:

| Field | Value |
|-------|--------|
| Email | `ahmed@example.com` |
| Password | `AhmedSales!123` |

### Session refresh and expiry

- Access tokens are short-lived. On HTTP 401 the client performs a **single-flight**
  refresh (`POST /api/v1/auth/refresh`) and retries the request.
- Concurrent 401s wait for the same refresh instead of treating the session as dead.
- **Network failure during refresh** does not expire the session — the user keeps
  working offline with the cached permission snapshot.
- If refresh fails because the refresh token is expired/revoked:
  - Sync **preference stays on**
  - Remote **RBAC snapshot stays** (same modules / PermissionGate access)
  - Tokens are cleared; SyncManager pauses until sign-in
  - Settings shows session-expired with a renew action
- Explicitly turning sync **off**:
  - **Administrators** (super admin / `devices.revoke` / platform admin) may
    disable sync on the device immediately.
  - **Regular users** cannot disable sync themselves. Toggling off sends
    `POST /api/v1/devices/sync-disable-requests`; an administrator reviews the
    request under Administration → Devices and may approve (revoke device →
    device returns to local full-admin mode) or reject (sync stays on).
