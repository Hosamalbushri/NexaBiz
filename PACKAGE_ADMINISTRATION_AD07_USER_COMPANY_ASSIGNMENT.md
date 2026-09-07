# PACKAGE ADMINISTRATION AD-07 — User ↔ Company Membership

## Executive Summary

Phase AD-07 establishes strict multi-tenant authorization boundaries by governing User-Company Membership lifecycle, company switching eligibility, server-side/client-side access enforcement, and local state eviction upon authorization loss.

---

## 1. Membership Rules & Authorization Principles

1. **Explicit Membership Required**: A user has zero access to any company data unless an explicit, active `UserCompanyMembership` record exists.
2. **Server-Side & Client-Side Dual Enforcement**:
   - **Backend API**: All endpoints validate `X-Company-ID` against the caller's active memberships.
   - **Frontend App**: Router guards, local Drift repositories, and synchronization queues restrict operations to authorized active companies.
3. **Company Switching Eligibility**: Switching the active workspace company requires calling `validateCompanySwitchEligibility(userId, targetCompanyId)` which verifies `status == 'active'`.
4. **Authorization Loss & Cache Invalidation**: Upon membership revocation or deactivation (`removeUserFromCompany` or status set to `inactive`), the local storage cache and pending sync queues scoped to that company are purged to prevent unauthorized data exposure.

---

## 2. Mandatory Verification Matrix (User U)

### Test Environment Matrix
- **User U**: Authenticated system user.
- **Company A**: Valid Active Membership (`active`).
- **Company B**: Valid Active Membership (`active`).
- **Company C**: No Membership / Unauthorized.

### Verification Flow Results

| Interface Layer | Target Company | Access Attempt | Expected & Validated Outcome |
| :--- | :---: | :---: | :--- |
| **API / Endpoint** | Company A | Request Data | `200 OK` — Data returned successfully |
| **API / Endpoint** | Company C | Request Data | `403 Forbidden` — Access Denied |
| **Company Switcher** | Company B | Switch Active Workspace | `Success` — Switch validated and active token context updated |
| **Company Switcher** | Company C | Switch Active Workspace | `ValidationFailure` — Switch denied due to missing active membership |
| **Route Guard** | Company C | Navigate `/companies/C/dashboard` | `Denied` — Redirected to unauthorized page |
| **Sync Queue** | Company C | Enqueue Offline Mutation | `Blocked` — Multi-tenant tenant boundary guard rejects mutation |
| **Local Repository** | Company C | Query Local Database | `Filtered out` — Drift repo tenant clause excludes Company C records |

---

## 3. Implementation Summary

- **Use Case**: Implemented `validateCompanySwitchEligibility` in `ManageAdminUsersUseCase` enforcing active membership checks and logging `user_company_switched` events.
- **Membership Lifecycle**: Implemented `assignUserToCompany`, `removeUserFromCompany`, and `setUserCompanyMembershipStatus` with full audit trail logging.

---

## 4. Verification Gate

```text
GATE CERTIFICATION:
[x] User access strictly limited to explicit active company memberships.
[x] Server-side and client-side route guards, sync queues, and local repos enforce company boundaries.
[x] Zero cross-company access through stale membership or cached state.
```
