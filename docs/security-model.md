# Security model

> Experimental — not production-ready.

## Pillars

1. **Authentication** — Argon2id passwords, JWT access (short TTL), hashed rotating refresh tokens
2. **Authorization** — RBAC permission codes, server authoritative
3. **Tenancy** — session company scope on every query
4. **Devices** — register / revoke
5. **Audit** — login, refresh reuse, role changes, sync auth failures, device revoke

## Local data assessment

| Data | Storage | Notes |
|------|---------|-------|
| Access/refresh tokens | `flutter_secure_storage` | Required |
| Auth snapshot (roles/perms) | Hive settings | UX offline; not a secret vault |
| Customers/sales/accounts | Drift SQLite | Unencrypted; OS sandbox |
| Sync queue | Hive | Contains business payloads |

Full DB encryption is **not** enabled yet — tradeoffs (key management,
performance, backup) should be decided before production.

## Production hardening remaining

- Disable `ALLOW_DEV_TOKEN`
- Strong `JWT_SECRET`, HTTPS-only, tighter CORS
- Rate limiting on login/refresh
- Per-tenant local DB isolation on company/user switch
- Optional SQLCipher / encrypted Hive
- Remove seed default passwords
- Lifespan handlers instead of deprecated `on_event`
- Broader automated IDOR / privilege-escalation suite
