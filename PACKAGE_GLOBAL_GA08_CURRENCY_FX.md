# PACKAGE_GLOBAL_GA08_CURRENCY_FX.md — Global Currency & FX Integrity Audit

## Executive Summary
This document provides the global currency and foreign exchange (FX) integrity audit for NexaBiz ERP. It verifies the strict architectural isolation and conversion rules between Document Currency, Base/Accounting Currency, and Inventory Valuation Currency. Crucially, posted economic transactions maintain immutable historical exchange rate bases; changing today's exchange rate NEVER retroactively alters historical inventory valuation or posted accounting entries.

---

## 1. 3-Tier Currency Model Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│ 1. Document Currency                                                        │
│    Currency used on customer/supplier face documents (e.g., USD, SAR, EUR) │
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 2. Base / Accounting Currency                                               │
│    Company functional ledger currency for financial reporting (e.g., YER, USD)│
└──────────────────────────────────────┬──────────────────────────────────────┘
                                       │
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 3. Inventory Valuation Currency                                             │
│    Company-scoped valuation currency for inventory cost layers (e.g., YER)   │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Historical Rate Immutability Invariant

### 2.1 Rule Definition
Once a stock receipt or journal entry is committed to the database, its cost basis in the valuation currency is calculated and frozen permanently:
$$\text{Valuation Cost Layer} = \text{Unit Cost (Document Currency)} \times \text{Exchange Rate}_{\text{posted\_date}}$$

### 2.2 Proof Scenario Verification
- **Setup**: Company Inventory Valuation Currency = `YER`.
- **Transaction 1 (Day 1)**: Stock Receipt of 10 items @ `10 SAR` each. Persisted Exchange Rate: `1 SAR = 140 YER`.
  - Calculated Layer Cost = $10 \times 140 = 1,400\text{ YER}$.
  - Total Receipt Value = $14,000\text{ YER}$.
- **Market FX Change (Day 2)**: Daily FX Rate updated to `1 SAR = 150 YER`.
- **Audit Assertion**:
  - The historical cost layer for Receipt 1 REMAINS **$1,400\text{ YER}$** (NOT $1,500\text{ YER}$).
  - Outbound COGS for items issued from Layer 1 continues to consume $1,400\text{ YER}$ per unit.
  - Historical journals remain strictly unchanged.

---

## 3. Module Currency Handling Audit Matrix

| Module | Currency Role | Conversion Mechanism | Rate Immutability Status |
|---|---|---|---|
| `sales` | Document Currency (Invoice Face) | Converted to Base via `CompanyAccountingConfig` rate | **IMMUTABLE** |
| `inventory` | Valuation Currency (Cost Layers) | Converted upon receipt posting | **IMMUTABLE** |
| `receipts_payments` | Document Currency (Voucher Face) | Allocated against customer balance in Base | **IMMUTABLE** |
| `cash_registers` | Cash Drawer Currency | Drawer balance stored in linked account currency | **IMMUTABLE** |
| `accounting` | Base Ledger Currency | Dual-currency recording (`amount_doc`, `amount_base`) | **IMMUTABLE** |
| `reports` | Reporting Projections | Query aggregates stored base currency fields | **IMMUTABLE** |

---

## 4. Test Matrix & Verification Results

- **Verified via**: `test/currency_exchange_test.dart`, `company_currency_and_accounting_config_test.dart`.
- **Test Results**:
  - Historical inventory layers retain original FX rates across rate updates: **PASSED**.
  - Journal entry debit and credit amounts in base currency match historical conversion: **PASSED**.
  - FX gain/loss on payment settlement calculates against historical document rate vs settlement rate: **PASSED**.

**GA-08 Gate Status**: **PASS**
