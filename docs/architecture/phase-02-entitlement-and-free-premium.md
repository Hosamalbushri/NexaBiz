# Phase 2 — Free/Premium Entitlement Architecture & Feature Capability Design

- **Status**: `IMPLEMENTED & VERIFIED`
- **Date**: 2026-08-25
- **Author**: Senior Software Architect

---

## A. Objective

Design and implement a centralized runtime entitlement system for NexaBiz to support:
1. **Free / Local-Only Mode**: Fully offline, zero cloud dependency, 100% local CRUD and accounting.
2. **Premium Mode**: Synchronization, cloud backups, multi-device access, and advanced features.
3. **Seamless Upgrades**: Upgrading from Free to Premium without data loss or re-installing.
4. **Decoupled Security**: Independent from Flutter Flavors, local boolean flags, or hardcoded UI toggles.

---

## B. Existing Architecture Audit Findings

| Component | Status / Existing Location | Findings |
| :--- | :--- | :--- |
| **Authentication** | `AuthSessionSnapshot`, `AuthUser` in `lib/modules/authentication/domain/entities/` | Manages user identity (`userId`), active tokens, and company membership. |
| **Company Context** | `TenantContext`, `currentCompanyIdProvider` in `lib/core/tenancy/tenant_context.dart` | Reactively isolates local database queries per tenant. |
| **Permissions / AuthZ** | `PermissionGate`, `permission_guard.dart` | RBAC permissions (e.g. `sales.create`, `inventory.view`) answer user-level company permissions. |
| **Settings & Storage** | `SettingsRepository`, `FlutterSecureStorage` | Manages local device settings and secure token storage. |
| **Backend API** | `/api/v1/auth/*`, `/api/v1/sync/*` | Laravel API endpoints for auth and synchronization. |
| **Sync Manager** | `SyncManager` in `lib/core/sync/sync_manager.dart` | Drains pending sync queues to cloud when enabled and online. |
| **Entitlements** | `NOT PRESENT` (Prior to Phase 2) | No entitlement model, capability service, or subscription gate previously existed. |

---

## C. Authentication vs Authorization vs Entitlement

| Concept | Question Answered | Managed By | Example |
| :--- | :--- | :--- | :--- |
| **Authentication (AuthN)** | *"Who is the user?"* | `AuthUser`, `userId` | User `U1` logged in via JWT. |
| **Authorization (AuthZ)** | *"What is this user allowed to do inside the company?"* | `AuthSessionSnapshot.permissions` | Accountant user allowed `sales.create`. |
| **Entitlement** | *"What capabilities has this company purchased?"* | `Entitlement`, `EntitlementCapability` | Company `C1` has `sync` and `cloudBackup`. |

---

## D. Entitlement Model

Located in `lib/core/entitlements/domain/entities/entitlement.dart`:

- **Tiers**: `free`, `premium`, `trial`, `enterprise`.
- **Statuses**: `active`, `expired`, `grace`, `cancelled`.
- **Sources**: `localDefault`, `cachedServer`, `activeServer`.
- **Fields**: `companyId`, `tier`, `status`, `capabilities`, `source`, `lastVerifiedAt`, `validFrom`, `validUntil`, `graceUntil`.

---

## E. Capability Model

Capabilities are represented as explicit `EntitlementCapability` enum symbols:
- `EntitlementCapability.sync`: Cloud synchronization engine.
- `EntitlementCapability.cloudBackup`: Automated cloud snapshot backups.
- `EntitlementCapability.multiDevice`: Multi-device sync registration.
- `EntitlementCapability.advancedReports`: Advanced analytics and reporting.
- `EntitlementCapability.multiBranch`: Multi-branch inventory tracking.
- `EntitlementCapability.teamUsers`: Team user invitations.
- `EntitlementCapability.cloudStorage`: Cloud attachment storage.

Capabilities are checked via `entitlement.hasCapability(capability)` or `entitlementService.requireCapability(capability)`.

---

## F. Free Capabilities

The default **Free** mode provides:
- Fully local operation (100% offline capable).
- Local CRUD across Inventory, Customers, Sales, Receipts/Payments, and Accounting.
- Local Chart of Accounts, Voucher Books, Fiscal Years, and Currency Rates.
- Local reports and PDF generation.
- Zero network, zero server authentication, and zero cloud API dependencies.

---

## G. Premium Capabilities

**Premium** mode unlocks:
- Automatic background & manual cloud synchronization (`sync`).
- Cloud database backups & snapshots (`cloudBackup`).
- Multi-device pairing & real-time sync (`multiDevice`).
- Advanced multi-period financial reporting (`advancedReports`).
- Team user invitations (`teamUsers`).

---

## H. Company Ownership Decision

**Decision**: Entitlements belong to the **Company** (`company_id`), NOT the individual user.

```text
Company (company_id)
   ↓
Subscription
   ↓
Entitlements (Capabilities)
   ↓
Users inherit company capabilities based on active company context
```

When a user switches companies, `currentCompanyIdProvider` updates and Riverpod reactively invalidates `currentEntitlementProvider`, switching capability evaluation dynamically to the target company.

---

## I. Offline Entitlement Policy

1. **Free Tier**: Always `ACTIVE` offline indefinitely. Requires 0 network connectivity.
2. **Premium Tier (Offline Grace)**:
   - Uses local encrypted cache in `FlutterSecureStorage` (`entitlement_<companyId>`).
   - Default offline grace duration: **14 days** (`offlineGraceDuration`).
   - If `lastVerifiedAt` is within 14 days, `status = GRACE` and Premium capabilities remain active.
   - If offline > 14 days without server verification, `status = EXPIRED`, revoking `sync` at the domain layer until online verification succeeds.

---

## J. Client vs Server Trust Model

- **Client Entitlement**: Drives local UX, widget visibility (`CapabilityGate`), and local domain guards (`SyncManager` pause). Can be modified locally on compromised devices, so it is **UX-only**.
- **Server Entitlement**: Acts as the authoritative cloud security boundary. Server API (`GET /api/v1/entitlements`, `POST /api/v1/sync/push`, `GET /api/v1/sync/pull`) validates JWT claims and database subscription records before authorizing sync or cloud operations.

---

## K. Flutter Architecture

1. **Entities**: [`Entitlement`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/domain/entities/entitlement.dart), [`EntitlementException`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/domain/entities/entitlement_exception.dart).
2. **Data Layer**: [`EntitlementRepositoryImpl`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/data/entitlement_repository.dart) (Secure cache & REST API client).
3. **Domain Layer**: [`EntitlementServiceImpl`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/domain/services/entitlement_service.dart) (Grace policy calculation & capability enforcement).
4. **Presentation Layer**: [`entitlement_providers.dart`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/presentation/providers/entitlement_providers.dart), [`CapabilityGate`](file:///home/hosam/StudioProjects/untitled2/lib/core/entitlements/presentation/widgets/capability_gate.dart).
5. **Sync Integration**: [`SyncManager`](file:///home/hosam/StudioProjects/untitled2/lib/core/sync/sync_manager.dart) checks `_hasSyncCapability` before starting sync passes.

---

## L. Laravel API Contract

Client fetches authoritative entitlement from Laravel backend via:

`GET /api/v1/entitlements`

```json
{
  "company_id": "c0123456-789a-bcde-f012-3456789abcde",
  "tier": "premium",
  "status": "active",
  "valid_from": "2026-01-01T00:00:00Z",
  "valid_until": "2027-01-01T00:00:00Z",
  "grace_until": "2027-01-15T00:00:00Z",
  "capabilities": [
    "sync",
    "cloud_backup",
    "multi_device",
    "advanced_reports",
    "team_users"
  ],
  "verified_at": "2026-08-25T03:20:00Z"
}
```

---

## M. Flavor Decision

- **Build-Time Flavors**: App ID, application name, app icon, base URL (`https://api.nexabiz.com`), Firebase config.
- **Runtime Entitlements**: Free/Premium tier, active/expired status, capabilities.
- **Principle**: `Flavor != Entitlement`. Flavors are never used to authorize Premium capabilities.

---

## N. Security Model

- UI gates (`CapabilityGate`) protect presentation and show upgrade prompts.
- Domain guards (`requireCapability`) protect local execution (`SyncManager.syncNow()`).
- Server API (`/api/v1/sync/*`) validates company subscription state on every HTTP request.

---

## O. Test Strategy

Created [`test/entitlement_architecture_test.dart`](file:///home/hosam/StudioProjects/untitled2/test/entitlement_architecture_test.dart) covering:
1. Free capability set (0 cloud capabilities).
2. Premium capability set (All purchased cloud capabilities granted).
3. Expired entitlement capability revocation.
4. Domain exception throwing on capability denial.
5. Offline grace policy evaluation (<14 days GRACE, >14 days EXPIRED).
6. Runtime state transitions (Free → Premium → Expired → Premium).
7. `CapabilityGate` widget presentation & upgrade prompt.

---

## P. Implementation Changes

1. `lib/core/entitlements/domain/entities/entitlement.dart` [NEW]
2. `lib/core/entitlements/domain/entities/entitlement_exception.dart` [NEW]
3. `lib/core/entitlements/data/entitlement_repository.dart` [NEW]
4. `lib/core/entitlements/domain/services/entitlement_service.dart` [NEW]
5. `lib/core/entitlements/presentation/providers/entitlement_providers.dart` [NEW]
6. `lib/core/entitlements/presentation/widgets/capability_gate.dart` [NEW]
7. `lib/core/sync/sync_manager.dart` [MODIFY]
8. `lib/core/sync/sync_providers.dart` [MODIFY]
9. `test/entitlement_architecture_test.dart` [NEW]
10. `docs/architecture/phase-02-entitlement-and-free-premium.md` [NEW]

---

## Q. Risks

- **Stale Offline Cache**: Solved by 14-day offline grace limit (`offlineGraceDuration`).
- **Spoofed Client Toggles**: Solved by domain-level guard in `SyncManager` and backend verification.

---

## R. Architecture Decision Record (ADR)

- **ADR-002**: Centralized Runtime Entitlement Architecture.
- **Decision**: Adopt capability-based runtime entitlements tied to `CompanyId`, with a 14-day offline grace policy and domain-level guard enforcement.

---

## Change Log

| Date | Author | Description of Changes |
| :--- | :--- | :--- |
| 2026-08-25 | Senior Software Architect | Phase 2 Implementation completed: Created `Entitlement`, `EntitlementCapability`, `EntitlementService`, `CapabilityGate`, secure cache repository, Riverpod provider integration, `SyncManager` domain guard, and 100% passing test suite. |
