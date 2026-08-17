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
| Access/refresh tokens | `flutter_secure_storage` | Required; AES Hive fallback if plugin unavailable |
| Auth snapshot / local users | Hive `local_auth_v2` | AES at rest (key in secure storage) |
| Sync queue | Hive `sync_queue_v2` | AES at rest; payloads include PII / amounts |
| Customers/sales/accounts | Drift SQLite | Unencrypted; OS sandbox |

Hive AES key: `HiveEncryptionKeyStore` (32 bytes in secure storage, or
degraded Hive `hive_key_fallback` when secure storage is unavailable).

Full Drift SQLCipher is **not** enabled yet — tradeoffs (key management,
performance, backup, five DB openers) remain deferred.

## Production hardening remaining

- Disable `ALLOW_DEV_TOKEN`
- Strong `JWT_SECRET`, HTTPS-only, tighter CORS
- Rate limiting on login/refresh
- Per-tenant local DB isolation on company/user switch
- Optional SQLCipher for Drift databases
- Remove seed default passwords
- Lifespan handlers instead of deprecated `on_event`
- Broader automated IDOR / privilege-escalation suite
- Third-party crash reporting (Sentry); local `AppErrorLog` is in place
