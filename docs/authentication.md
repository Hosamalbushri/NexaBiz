# Authentication

> Experimental — not production-ready.

## Overview

NexaBiz uses **JWT access tokens** + **rotating refresh tokens** with
company-scoped sessions and device registration.

```
Flutter SessionManager / AuthRepository
        │
 SecureTokenStorage (flutter_secure_storage)
        │
 AuthenticatedHttpClient  (refresh-on-401 once)
        │
 FastAPI /api/v1/auth/*
```

## Endpoints

| Method | Path | Purpose |
|--------|------|---------|
| POST | `/api/v1/auth/login` | Email/password → tokens + permissions |
| POST | `/api/v1/auth/refresh` | Rotate refresh token |
| POST | `/api/v1/auth/logout` | Revoke session |
| GET | `/api/v1/auth/me` | Current user/company/roles/permissions |
| POST | `/api/v1/auth/switch-company` | Change company context (new tokens) |

## Seed accounts

| Email | Password | Role |
|-------|----------|------|
| `admin@example.com` | `ChangeMeAdmin!123` | Super Admin |
| `ahmed@example.com` | `AhmedSales!123` | Sales Employee (Company A) |

## Flutter flow

1. App bootstrap loads secure tokens + Hive authorization snapshot.
2. If refresh works → authenticated; else → login.
3. Login registers device UUID and stores tokens securely.
4. Permissions snapshot (Hive) drives offline UI gates only.

## Policy notes

- Logout clears tokens/session snapshot; **does not** wipe Drift business data by default.
- Company switch issues new tokens; local multi-tenant DB isolation is a follow-up.
- Dev shared bearer (`DEV_API_TOKEN`) remains as a fallback for tools; prefer JWT.
