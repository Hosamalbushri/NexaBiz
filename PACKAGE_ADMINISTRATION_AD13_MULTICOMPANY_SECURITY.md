# PACKAGE ADMINISTRATION AD-13 — Multi-Company Security

## Executive Summary

Phase AD-13 certifies multi-tenant isolation and strict server-side membership validation across all administrative domain entities, local caches, sync queues, and API endpoints.

---

## 1. Adversarial Test Setup: User U Context

- **User U**: Authenticated User.
- **Company A**: Active Membership (`Role: Sales Manager`, Full Read/Write).
- **Company B**: Active Membership (`Role: Viewer`, Read Only).
- **Company C**: No Membership (Unauthorized Target).

---

## 2. Cross-Domain Verification Matrix

| Domain / Subsystem | Attack Vector | Security Mechanism | Result |
| :--- | :--- | :--- | :--- |
| **API Endpoints** | Inject header `X-Company-ID: Company C` | Middleware validates caller's active token membership | `403 Forbidden` — Rejected |
| **Users API** | Request users list for Company C | Server queries tenant scope derived from token | `403 Forbidden` — Rejected |
| **Roles & Perms** | Switch context to B & attempt `roles.create` | Role permissions evaluated in Company B context (Viewer) | `ValidationFailure` — Permission Denied |
| **Branches** | Move branch from Company A to Company B | Tenant guard verifies source & target company matching | `ValidationFailure` — Cross-tenant mutation blocked |
| **Company Settings** | Patch settings for Company C | Policy guard checks active membership for target company | `403 Forbidden` — Rejected |
| **Audit Logs** | Query audit log history for Company C | Audit repository filters by authenticated company memberships | Empty list / `403 Forbidden` |
| **Local Cache** | Read Drift DB table without tenant clause | Drift queries automatically append `WHERE company_id = :activeCompanyId` | Data strictly isolated to active company |
| **Sync Outbox** | Inject mutation for Company C into outbox | Sync engine tenant guard validates payload company ID against session token | Queue item dropped with `TenantViolation` error |

---

## 3. Server-Side Derived Authority Principle

> [!CAUTION]
> **Client ID Non-Trust Invariant**: The backend server **never** trusts client-supplied `companyId` input parameters or HTTP headers without validating that the authenticated user possesses an explicit, active `UserCompanyMembership` for that specific company ID.

---

## 4. Verification Gate

```text
GATE CERTIFICATION:
[x] Client-supplied companyId inputs are validated server-side against authenticated memberships.
[x] Zero cross-company data access, data leaks, or unauthorized mutations.
[x] Local Drift DB queries and sync outbox payloads strictly company-scoped.
```
