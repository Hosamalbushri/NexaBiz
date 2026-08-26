# NexaBiz Architecture Documentation Index

Welcome to the NexaBiz Architecture Documentation index. This directory contains detailed specifications and implementation records for multi-tenancy, subscription entitlement, authorization, and data safety boundaries.

---

## Architecture Documents

1. **[Phase 1 — Data Ownership & Tenancy](file:///home/hosam/StudioProjects/untitled2/docs/architecture/phase-01-data-ownership-and-tenancy.md)**
   - Tenancy isolation via strict `company_id` filters on Drift SQLite tables.
   - Elimination of NULL company_id wildcards.

2. **[Phase 2 — Subscription Entitlement & Grace Policy](file:///home/hosam/StudioProjects/untitled2/docs/architecture/phase-02-entitlements.md)** *(Legacy doc)*
   - Entitlement mapping (Free, Premium, Trial).
   - 14-day premium offline grace duration checks.

3. **[Phase 3 — Authentication, Offline Identity & Authorization Hardening](file:///home/hosam/StudioProjects/untitled2/docs/architecture/phase-03-authentication-and-offline-authorization.md)**
   - Hardening JWT sessions, device binding, and key-based Hive snapshot separation.
   - central `AuthorizationContext` reactive propagation.

4. **[Phase 4 — Offline Data Access Security, Session Isolation & Authorization Enforcement](file:///home/hosam/StudioProjects/untitled2/docs/architecture/phase-04-offline-data-access-security.md)**
   - Enforcing `companyId` and `deviceId` metadata on `SyncOperation` instances.
   - Scoped `SyncQueue` peek and quarantine protections on `SyncManager` uploads.
   - Centralized `LocalAccessPolicy` domain guard checks.
