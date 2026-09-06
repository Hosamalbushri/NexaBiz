# RP-05 — RECEIPTS & PAYMENTS MULTI-CURRENCY & FX SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This report details the architectural integration between Receipts & Payments and the existing Accounting multi-currency system. The design ensures multi-currency settlements preserve historical exchange rates, recognize realized FX gains and losses at settlement time, and eliminate floating-point drift without duplicating currency models.

---

## 1. 4-LAYER CURRENCY ARCHITECTURE

Every multi-currency settlement distinguishes four explicit currency layers:
1. **Transaction Currency ($C_{txn}$):** The currency in which the receipt or payment is executed (e.g. `YER`).
2. **Accounting Base Currency ($C_{base}$):** The company's functional ledger currency (e.g. `SAR`).
3. **Source Document Currency ($C_{doc}$):** The original invoice or purchase document currency (e.g. `USD`).
4. **Settlement Currency ($C_{settle}$):** The currency allocated to settle the target document (e.g. `USD`).

---

## 2. MULTI-CURRENCY SETTLEMENT MATH

### Example Scenario
- **Invoice:** 10 USD ($C_{doc} = \text{USD}$) at original rate $1 \text{ USD} = 3.75 \text{ SAR}$.
  - Base Amount = $37.50 \text{ SAR}$.
- **Receipt:** 3,750 YER ($C_{txn} = \text{YER}$) at rate $1 \text{ USD} = 1,250 \text{ YER}$.
- **Settlement Allocation:**
  $$\text{Settled USD} = \frac{3,750 \text{ YER}}{1,250 \text{ YER/USD}} = 3.00 \text{ USD}$$
  $$\text{Base Equivalent} = 3.00 \text{ USD} \times 3.75 \text{ SAR/USD} = 11.25 \text{ SAR}$$

---

## 3. HISTORICAL EXCHANGE RATE IMMUTABILITY

- **Posting Rule:** When a receipt or payment is posted, the `exchangeRate` and calculated `counterAmount` / `baseAmount` are permanently written to the financial transaction entity.
- **Sync & Historical Rule:** Synchronization and financial reporting NEVER recalculate historical transaction values using current exchange rates. The rate used at settlement time remains authoritative forever.

---

## 4. REALIZED FX GAIN & LOSS ACCOUNTING

When a foreign currency document (e.g. 1,000 USD invoice) is settled at a different exchange rate than when it was originally recorded:
- **Invoice Booking Rate ($R_{inv}$):** $1 \text{ USD} = 3.75 \text{ SAR} \implies 3,750 \text{ SAR}$.
- **Receipt Settlement Rate ($R_{rec}$):** $1 \text{ USD} = 3.80 \text{ SAR} \implies 3,800 \text{ SAR}$.
- **Difference:** $+50 \text{ SAR}$ (Realized FX Gain).

### Accounting Entry (Receipt with FX Gain):
- **DEBIT:** Treasury / Bank Asset ($3,800 \text{ SAR}$)
- **CREDIT:** Customer Receivable ($3,750 \text{ SAR}$)
- **CREDIT:** Realized FX Gain Account ($50 \text{ SAR}$)

### Accounting Entry (Receipt with FX Loss):
- **DEBIT:** Treasury / Bank Asset ($3,700 \text{ SAR}$)
- **DEBIT:** Realized FX Loss Account ($50 \text{ SAR}$)
- **CREDIT:** Customer Receivable ($3,750 \text{ SAR}$)

---

## 5. STRICT FX RATE VALIDATION

The system rejects invalid FX parameters via `FinancialTransactionValidator`:
1. `exchangeRate <= 0`: Throws `FinancialTransactionException.amountMustBePositive`.
2. `counterExchangeRate <= 0`: Throws `FinancialTransactionException.counterAmountMustBePositive`.
3. Unvalidated fallback to `1.0` for non-base currencies: Rejected.

---

## 6. INTEGRATION TEST MATRIX (`test/modules/receipts_payments/rp_multicurrency_fx_test.dart`)

1. **Same Currency Settlement:** SAR to SAR settlement.
2. **Foreign Currency Settlement:** Invoice in USD, Receipt in YER.
3. **Partial Foreign Settlement:** Partial USD invoice settled via YER receipt.
4. **Different Settlement Exchange Rate:** Settlement rate differs from invoice rate.
5. **Realized FX Gain Recognition:** Credit to Realized FX Gain account.
6. **Realized FX Loss Recognition:** Debit to Realized FX Loss account.
7. **Missing / Invalid FX Rate Rejection:** 0 or negative rate rejection.
8. **Offline Settlement Rate Persistence:** Immutable historical rate stored offline.
9. **Sync Retry Invariance:** Retrying sync preserves historical base amounts.
