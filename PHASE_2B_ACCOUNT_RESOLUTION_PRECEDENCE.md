# PHASE 2B — ACCOUNT RESOLUTION PRECEDENCE SPECIFICATION (HARDENED)

## 1. Executive Summary
This document establishes the canonical, deterministic Account Resolution Precedence algorithm and Role Applicability Matrix for the NexaBiz ERP Financial Package (Phase 2B GATE-05). All financial and operational modules MUST route account resolution through `CanonicalAccountResolverService`.

---

## 2. Canonical Role Applicability Matrix

The Account Resolver MUST first determine whether a resolution source is applicable to the requested financial role before evaluating precedence.

| Financial Role | Context Applicable? | Subject Applicable? | Company Mapping Applicable? |
|---|---|---|---|
| `CUSTOMER_RECEIVABLE` | **NO** | **YES** | **YES** (fallback) |
| `SUPPLIER_PAYABLE` | **NO** | **YES** | **YES** (fallback) |
| `SALES_REVENUE` | **YES** | **NO** | **YES** |
| `PURCHASE_EXPENSE` | **YES** | **NO** | **YES** |
| `COGS` | **YES** | **NO** | **YES** |
| `INVENTORY` | **YES** | **NO** | **YES** |
| `CASH` | **YES** | **NO** | **YES** |
| `BANK` | **YES** | **NO** | **YES** |
| `TAX` | **NO** | **NO** | **YES** |
| `FX_GAIN_LOSS` | **NO** | **NO** | **YES** |

---

## 3. Resolution Precedence & Source Semantics

```text
RESOLUTION ALGORITHM:
requestedRole
    ↓
Role Applicability
    ↓
Applicable Sources
    ↓
Source State (UNCONFIGURED vs CONFIGURED_INVALID)
    ↓
Validation
    ↓
FinancialAccount.id
```

### 3.1 `UNCONFIGURED` vs `CONFIGURED BUT INVALID` Semantics
- **`UNCONFIGURED` Source:**
  When an applicable resolution source has no binding configured (e.g. `contextId` unconfigured or `subject.primaryAccountId` is empty), the resolver **continues to the next applicable source**.
- **`CONFIGURED BUT INVALID` Source:**
  When an applicable resolution source IS configured but points to an invalid candidate (e.g. inactive account, deleted account, group account, cross-company account, or inactive subject), the resolver **FAILS CLOSED IMMEDIATELY**.
  **No silent fallback to lower-precedence layers is permitted.**

---

## 4. Operational Failure Semantics (Fail-Closed)

1. **`MISSING_ACCOUNT_MAPPING`:**
   Thrown when all applicable resolution sources are unconfigured. **Zero hardcoded fallback account codes ('4100', '5100', '1210', '1230', etc.) are permitted.**
2. **`INACTIVE_ACCOUNT`:**
   Thrown when a configured candidate account has `isActive == false` or `isDeleted == true`.
3. **`CROSS_TENANT_ACCOUNT_REJECTION` / `CROSS_TENANT_SUBJECT_REJECTION`:**
   Thrown when a candidate account or subject belongs to a company other than `operation.companyId`.
4. **`GROUP_ACCOUNT_NOT_POSTABLE`:**
   Thrown when a candidate account has `isGroup == true`.
5. **`ILLEGAL_ACCOUNT_CODE_AS_IDENTITY`:**
   Thrown if a numeric code is passed as a technical identity.

---

## 5. Technical Identity Mandate
- The resolver returns strictly **`FinancialAccount.id`** (UUID v7).
- Account numbers/codes (`FinancialAccount.code`) are mutable human references and are **NEVER** used as technical identity.
- Account code mutations and account hierarchy moves do NOT alter resolution identity.

---

## 6. Non-Execution Boundary & Zero Currency Operations
- The resolver is strictly a lookup and validation pipeline. It MUST NOT:
  - Post journal entries.
  - Mutate account balances.
  - Perform currency conversions, base calculations, or exchange rate snapshots.
- **GATE-06 Boundary:** Context internal hierarchy (e.g., Branch > Warehouse > Register) is NOT defined by GATE-05 and remains deferred to GATE-06.
