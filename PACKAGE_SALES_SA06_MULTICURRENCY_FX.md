# SA-06 — Sales Multi-Currency & FX Integrity

## Overview
This document specifies the architectural rules and domain standards for integrating Sales with the NexaBiz multi-currency and FX system without duplicating currency structures, rewriting historical inventory cost layers, or introducing dynamic FX rate fallbacks.

---

## 1. Distinct Economic Currencies
The system distinguishes three distinct currency scopes across every sales transaction:

1. **Sales Document Currency:** The transaction billing currency in which sales prices, items, discounts, taxes, and customer receivables are quoted (e.g. `SAR`).
2. **Inventory Valuation Currency:** The company-scoped functional currency in which historical inventory cost layers and asset valuations are recorded (e.g. `YER`).
3. **Accounting Base Currency:** The reporting currency of the General Ledger (e.g. `SAR` or `YER`).

---

## 2. Historical Inventory Valuation Preservation
- **Rule:** Inventory cost layers store original asset costs in the company's valuation currency (`unitCostInventoryCurrency`).
- **Example Scenario:**
  - Original receipt cost layer: `10 SAR` with initial FX = `140` → `1,400 YER`.
  - Later market FX rate fluctuates to `150`.
  - When a sale occurs later at `10 SAR`, COGS consumes the layer at its original historical valuation cost of `1,400 YER`.
  - **Forbidden:** The system **MUST NOT** recalculate historical cost layers or transform the cost layer to `1,500 YER` due to market FX changes. Historical inventory cost is immutable.

---

## 3. Explicit Sales FX Rate Persistence
- Every sale document explicitly persists:
  - `currencyCode`: Document billing currency code.
  - `baseCurrencyCode`: Accounting base currency code.
  - `exchangeRate`: The exact exchange rate active at document creation.
- **Rule:** The system must **NEVER** silently default to `1.0`, the latest exchange rate, or current market rate when historical exchange rate data exists.
- Offline transactions persist complete FX metadata to ensure that synchronization re-applies identical monetary amounts without recalculating historical values.

---

## 4. Accounting Ledger Integration
- Integrates cleanly with core accounting primitives:
  - `JournalMoney` / monetary amounts in line drafts.
  - `AccountingEntryBuilder`:
    - Sales revenue, tax, discount, and cash/receivable lines inherit the document `currencyCode` and persisted `exchangeRateToBase`.
    - COGS lines inherit the inventory valuation base currency (`baseCurrencyCode`) derived directly from inventory cost layers.

---

## 5. Sales Returns & Reversals Economic Fidelity
- When a sale is returned or cancelled:
  - Consumed cost layers are restored to `inventory_cost_layers` using `reverseConsumptions(issueLineUuid)`.
  - Restored layer quantities and unit costs reflect the original receipt valuation.
  - Returns **NEVER** evaluate today's market FX rate to adjust past COGS or rewrite historical cost layer balances.

---

## 6. Offline Persistence & Synchronization Safety
- All offline sale drafts record complete currency metadata (`currencyCode`, `baseCurrencyCode`, `exchangeRate`).
- When an offline sale syncs to the server or background database, the persisted `exchangeRate` is strictly maintained. The sync process must **NEVER** re-query exchange rate services to overwrite historical transaction rates.

---

## 7. Verification Matrix
Verified via `test/modules/sales/sales_multicurrency_fx_test.dart` covering:
1. Multi-currency separation (Document Currency vs. Inventory Valuation Currency vs. Accounting Base Currency).
2. Historical inventory cost layer preservation under market FX rate fluctuations (140 → 150).
3. Transaction FX rate persistence and prohibition of dynamic rate fallbacks.
4. Sales return economic fidelity (restoring original layer costs and FX rates).
5. Offline transaction FX persistence and sync idempotency.
