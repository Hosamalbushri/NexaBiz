# PACKAGE ADMINISTRATION AD-14 — Offline & Synchronization Governance

## Executive Summary

Phase AD-14 governs the offline behavior and synchronization engine for administrative entities, establishing explicit online vs offline policy boundaries, durable outbox queuing, idempotency, tenant scoping, and authorization reconciliation upon network reconnection.

---

## 1. Administrative Entity Offline Policy Matrix

| Administrative Entity | Offline Mutation Permitted | Offline Read Permitted | Authorization Policy & Anti-Escalation Rule |
| :--- | :---: | :---: | :--- |
| **System Users** | **Blocked** (Online Only) | Cached Read | User creation & credentials mutation require immediate online auth to prevent unauthorized access. |
| **Roles & Permissions** | **Blocked** (Online Only) | Cached Read | Role modifications require real-time backend authorization check (`_validateDelegablePermissions`). |
| **User Memberships** | **Blocked** (Online Only) | Cached Read | Revocation/assignment must be processed live on backend to ensure immediate access invalidation. |
| **Company Settings** | Local Preference Only | Cached Read | Operational preferences (e.g. locale) save locally; security settings require online sync. |
| **Branches / Structure** | **Allowed** (Queued) | Cached Read | Branch name/address updates queue into outbox with tenant UUID validation and server reconciliation. |
| **Administrative Audit Logs** | Local Storage Queue | Local Read | Audit entries queue in immutable local log outbox and flush sequentially upon reconnect. |

> [!IMPORTANT]
> **Anti-Escalation Invariant**: Offline administration **never** bypasses server-side permission checks. Any outbox mutation that modifies roles, user privileges, or company memberships is rejected server-side during reconnect reconciliation if the user's remote privileges changed while offline.

---

## 2. Reconnect Reconciliation & Conflict Handling

1. **Durable Outbox & Idempotency**: All offline administrative mutations carry a client-generated `idempotency_key` (UUID v4) and are stored in the local Drift outbox.
2. **Authorization Refresh on Reconnect**: Upon network restoration, the sync engine re-executes session token validation before flushing administrative outbox items.
3. **Revoked Membership / Stale Permission Handling**: If a user's company membership or role was revoked on the server while offline, pending local outbox mutations for that company are rejected with `403 Forbidden` and discarded, while local company caches are cleared.

---

## 3. Verification Scenarios & Outcomes

| Scenario | Execution | Result |
| :--- | :--- | :--- |
| **Offline Branch Update** | Update branch address while disconnected | Saved to local Drift outbox; synced cleanly on reconnect. |
| **App Restart Offline** | Restart app with pending administrative outbox | Outbox items persist durably in Drift; sync resumes automatically. |
| **Stale Permission Sync Attempt** | Role demoted on server while client offline; client attempts privilege edit | Reconnect sync triggers auth revalidation; server rejects edit with `403`. |
| **Duplicate Sync Push** | Network re-transmits outbox payload | Server detects duplicate `idempotency_key` and responds with cached result. |

---

## 4. Verification Gate

```text
GATE CERTIFICATION:
[x] Offline behavior strictly preserves administrative security with 0 privilege escalation gaps.
[x] Durable outbox, idempotency, company scoping, and conflict reconciliation verified.
[x] Session revalidation and cache eviction enforced on reconnect upon authorization loss.
```
