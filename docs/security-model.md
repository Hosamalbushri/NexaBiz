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
| Sync queue | Hive `sync_queue_v2` (+ `{hex}` per company) | AES at rest; payloads include PII / amounts |
| Pull cursors | Hive `sync_cursors` (+ `{hex}` per company) | Per-company sequences so a switch cannot skip/replay another tenant |
| Customers/sales/accounts | Drift SQLite | **SQLCipher** (SQLite3MultipleCiphers when hooks enabled); OS sandbox; **one file set per company** |

Hive AES key: `HiveEncryptionKeyStore` (32 bytes in secure storage, or
degraded Hive `hive_key_fallback` when secure storage is unavailable).

Drift SQLCipher key: `DriftEncryptionKeyStore` (32-byte seed in secure
storage, base64url passphrase). Plaintext `$name.sqlite` files from older
builds are migrated on first open when cipher is linked.

`pubspec.yaml` enables SQLite3MultipleCiphers:

```yaml
hooks:
  user_defines:
    sqlite3:
      source: sqlite3mc
```

When hooks are not active (some desktop test runners), Drift falls back to
plaintext with a debug log — mobile release builds must ship with hooks.

## Crash reporting

| Layer | Role |
|-------|------|
| `AppErrorLog` | Always-on local append-only file (`logs/app_errors.log`) |
| Sentry | Optional when `SENTRY_ENABLED=true` + non-empty `SENTRY_DSN` dart-define |

Sentry is fail-closed by default (no DSN in repo). `sendDefaultPii` is off;
performance tracing sample rate is `0` (errors only).

## Production hardening remaining

Server-side IDOR / privilege-escalation regression tests:
`backend/tests/test_auth_rbac.py` (roles, memberships, sync push, tenant headers).
