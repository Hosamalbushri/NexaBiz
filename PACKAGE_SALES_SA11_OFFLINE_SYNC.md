# SA-11 — Sales Offline-First, Sync & Idempotency Integrity

## Overview
This document specifies the architectural rules, transaction atomicity standards, cloud synchronization contracts, duplicate retry idempotency guarantees, non-silent conflict rejection policies, and multi-tenant scoping for offline sales execution.

---

## 1. Offline Posting Preservation
When a sale invoice is posted while operating offline, the local Drift SQLite storage atomically persists the complete economic payload:
- **Identity & Context:** `uuid`, `companyId`, `saleNumber`, `saleDate`, `settlementType`.
- **Party Context:** `customerId`, `customerAccountId`, `walkInCustomerName`, `cashAccountId`.
- **Location Context:** `warehouseId` (explicit UUID requirement).
- **Monetary Snapshot:** `currencyCode`, `baseCurrencyCode`, `exchangeRate`, `subtotal`, `itemDiscountTotal`, `discountType`, `discountValue`, `discountAmount`, `taxRate`, `taxAmount`, `total`, `paidAmount`, `remainingAmount`.
- **Inventory COGS Snapshot:** `costingMethod`, `inventory_cost_consumptions` (consumed layer IDs, quantities, unit costs, historical layer values).
- **Accounting GL Drafts:** Debits (`Cash` / `Customer Receivable`, `Sales Discount`) and Credits (`Sales Revenue`, `Tax Payable`, `COGS`, `Inventory Asset`).
- **Sync Flags:** `syncStatus` set to `SyncStatus.pending`, `lastSyncedAt = null`, `version = 1`.

---

## 2. Local Transaction Atomicity (Zero Partial States)
All local database operations executing an offline sale post occur inside a single atomic database transaction (`db.transaction(...)`).

The atomicity engine enforces that **no partial economic state can ever exist**:
- **NO Sale without Stock Movement:** Stock deductions and inventory consumption layers are committed in the same transaction.
- **NO Stock Movement without Sale:** Inventory layer consumptions reference the posting `saleUuid`.
- **NO Payment without Sale:** Payment receipts/allocations reference the posting `saleUuid`.
- **NO COGS without Inventory Layer Consumption:** Accounting COGS entries reflect exact layer valuations returned by `CostLayerService`.

If any operation fails (e.g. insufficient stock or missing CoA account), the entire local transaction aborts and rolls back completely.

---

## 3. Synchronization Immutable Snapshot Rule
When the device reconnects and pushes pending sales to the server:
- **No Dynamic Recalculation:** The sync engine payload carries the original offline economic values.
- The server or cloud sync handler **MUST NOT recalculate**:
  - `subtotal`, `taxAmount`, `discountAmount`, or `total`.
  - Historical line unit prices.
  - Historical exchange rates (`exchangeRate`).
  - Historical inventory unit costs or COGS amounts.
- Historical economic snapshots generated at transaction time remain frozen and authoritative.

---

## 4. Duplicate Sync Retry Idempotency
Network interruptions may cause a client to re-send a sync payload for an already-received sale:
- **UUID Deduplication:** The sync receiver uses `sale.uuid` as the unique idempotency key.
- **Idempotent Retry Processing:** Re-transmitting an existing sale `UUID`:
  - Returns `200 OK` / `SyncStatus.synced`.
  - **Does NOT create duplicate Sale rows**.
  - **Does NOT duplicate stock deductions**.
  - **Does NOT duplicate COGS consumptions**.
  - **Does NOT duplicate General Ledger journal entries**.
  - **Does NOT duplicate payment movements or customer receivable balances**.

---

## 5. Non-Silent Conflict Resolution Policy
Economic transactions must never be silently merged or dynamically overwritten.

When a synchronization conflict is detected:
1. **Conflicting Edits:** If the same sale document was edited on multiple offline devices, the sync engine flags a `SyncConflictRecord` with `ConflictStrategy.manual`.
2. **Stock Shortage:** If server-side inventory layers differ, the sale is quarantined in a conflict state.
3. **Modified Monetary Payload:** Re-pushing an existing `UUID` with altered monetary amounts flags a data integrity violation.
4. **Resolution:** Conflicting sales require explicit administrative review. Silent overwrites or field-level automatic merging are strictly prohibited.

---

## 6. Multi-Company Scope Isolation
- Every offline sale payload explicitly persists `companyId`.
- Sync queries (`sync_queue`) filter strictly by the active `companyId`.
- Cross-company sync payloads are rejected with `SyncErrorCode.companyMismatch`.

---

## 7. Verification Matrix
Verified via `test/modules/sales/sales_offline_sync_test.dart` covering:
1. Offline sale posting atomicity (complete economic state persistence without partial states).
2. Snapshot preservation (zero recalculation of totals, unit prices, FX, or COGS during sync).
3. Duplicate sync retry idempotency (pushing identical UUID returns existing record without duplicating GL/inventory side effects).
4. Non-silent conflict rejection (flagging `SyncConflictRecord` on payload discrepancies).
5. Multi-tenant company scope isolation during sync queue processing.
