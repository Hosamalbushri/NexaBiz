# RP-10 — RECEIPTS & PAYMENTS OFFLINE, SYNC & MULTI-COMPANY SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report defines the architecture for local offline transaction persistence, atomicity, idempotency, multi-tenant company isolation, and historical economic preservation during synchronization retries for the Receipts & Payments module.

---

## 1. OFFLINE LOCAL PERSISTENCE ENGINE

When operating offline without a network connection, every created or posted receipt/payment is durably persisted in local storage (`ReceiptsPaymentsDatabase` via Drift):

- **Identity & Scope:** `uuid` (v4 UUID), `companyId` (Tenant ID), `documentNumber` (Voucher book allocation).
- **Financial Payloads:** `amount`, `currencyCode`, `baseCurrencyCode`, `exchangeRate`, `counterAmount`, `counterCurrencyCode`, `counterExchangeRate`.
- **Account & Counterparty:** `cashAccountId`, `counterAccountId`, `customerId`, `paymentMethod`.
- **Allocations:** List of target document allocation records (`documentId`, `allocatedAmount`, `currencyCode`).
- **Posting & Sync Metadata:** `documentStatus` (`unposted` | `posted`), `idempotencyKey` (`rp_post:{uuid}`), `createdAt`, `updatedAt`.

---

## 2. LOCAL TRANSACTION ATOMICITY

All 4 transactional effects commit or rollback atomically in a single local database transaction:

```text
       ┌──────────────────────────────┐
       │   Financial Transaction      │
       └──────────────┬───────────────┘
                      │
   ┌──────────────────┼──────────────────┐
   ▼                  ▼                  ▼
┌──────────┐    ┌───────────┐    ┌──────────────┐
│  GL      │    │ Cash Reg  │    │ Allocations  │
│ Journal  │    │ Movement  │    │  Records     │
└──────────┘    └───────────┘    └──────────────┘
```

**Atomicity Guarantee:**
- No payment without accounting GL entry.
- No accounting GL entry without payment.
- No allocation record without payment.
- No cash movement without payment.

---

## 3. HISTORICAL ECONOMIC SYNC PRESERVATION

Synchronization with the central server or remote node MUST preserve the original economic transaction snapshot:
- **No Rate Recalculation:** Historical $FX_{rate}$ recorded at transaction time MUST NOT be recalculated using today's spot rate.
- **No Amount Recalculation:** Original transaction amount $A_{txn}$ and base amount $A_{base} = A_{txn} \times FX_{rate}$ MUST be transmitted verbatim.
- **No Allocation Recalculation:** Original allocation breakdown $\sum a_i$ MUST be preserved.

---

## 4. DUPLICATE SYNC IDEMPOTENCY

When a network timeout occurs during sync transmission, retrying the synchronization sequence MUST NOT duplicate:
- Receipts or Payments
- Accounting GL Journal Entries
- Cash Register Movements
- Customer or Supplier Account Balances
- Allocation Records

Idempotency is enforced by matching `idempotencyKey` or `uuid` on the receiving endpoint.

---

## 5. STRICT MULTI-TENANT COMPANY ISOLATION

Repository queries and database operations strictly enforce company scoping:

```sql
SELECT * FROM financial_transactions 
WHERE company_id = :tenantCompanyId 
  AND uuid = :transactionUuid;
```

**Tenant Isolation Invariant:** Company A can NEVER query, mutate, allocate, or post transactions, cash registers, customers, or accounts belonging to Company B.

---

## 6. CONCURRENT OVER-ALLOCATION PROTECTION

When multiple devices attempt to allocate against the same outstanding invoice balance ($O_{inv}$) simultaneously:
- Each allocation operation acquires a transactional lock on the target invoice balance.
- Maximum allocatable amount is strictly bounded:

$$a_{alloc} \le \min\left(A_{rem}, O_{inv}\right)$$

- Any concurrent allocation exceeding the updated outstanding balance is safely rejected or capped.

---

## 7. INTEGRATION TEST MATRIX (`test/modules/receipts_payments/rp_offline_sync_test.dart`)

1. **Offline Transaction Persistence & Lifecycle:** Creates transaction offline; simulates app restart; verifies full payload.
2. **Local 4-Way Transaction Atomicity:** Verifies transaction + GL + cash register + allocation commit atomically.
3. **Historical Economic Sync Preservation:** Verifies original historical exchange rate and base amounts are preserved during sync.
4. **Duplicate Sync Retry Idempotency:** Retries sync 3 times; verifies exactly 1 transaction and GL entry exist.
5. **Strict Multi-Tenant Company Isolation:** Verifies Company A cannot access Company B transactions or registers.
6. **Concurrent Allocation Over-Allocation Protection:** Simulates concurrent device allocations capping at outstanding balance.
7. **Full Offline $\rightarrow$ Restart $\rightarrow$ Sync $\rightarrow$ Retry $\rightarrow$ Ack Lifecycle:** Complete end-to-end lifecycle verification.
