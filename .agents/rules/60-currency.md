# 60 — MULTI-CURRENCY & EXCHANGE RATE GOVERNANCE

## 1. Currency Philosophy
1. **Canonical Currency Authority**: All currency conversions, exchange rate validations, and journal base amount resolutions MUST route through the centralized currency engine.
2. **Established Project Components**: The production paths MUST converge upon and utilize the canonical currency primitives:
   * `ExchangeRateValidator`
   * `ExchangeRateEngine`
   * `JournalBaseAmountResolver`
   * `JournalBalanceValidator`

---

## 2. Currency Classifications
1. **Main Company Base Currency**: The primary reporting currency configured for a company (e.g., `SAR`).
2. **Transaction Currency**: The currency in which a specific operational document (e.g., Invoice, Purchase Order, Receipt) is issued (e.g., `YER`).
3. **Inventory Currency**: The canonical currency in which stock cost valuation is maintained.

---

## 3. Exchange Rate Rules & Prohibition of Defaults
1. **Effective Rate Determination**: Exchange rates MUST be resolved dynamically based on currency pair `(from_currency, to_currency)`, active `company_id`, and transaction `effective_date`.
2. **Prohibition of Rate Fallbacks**: The system MUST NEVER silently fall back to `1.0` or an arbitrary rate when an exchange rate is missing. Missing rates MUST trigger an explicit, blocking error:

```dart
// FORBIDDEN SILENT FALLBACK
final rate = rateFromDb ?? 1.0; // STRICTLY PROHIBITED
```

3. **Rate Directionality**: Exchange rate direction (Source → Target vs Target → Source) MUST be explicitly defined and verified against `ExchangeRateValidator` to prevent inverted rate calculations.

---

## 4. Conversion Invariants & Prevention of Double Conversion
1. **Single Conversion Path**: Monetary conversion MUST occur exactly ONCE when computing transaction base amounts or GL journal line base amounts.
2. **Canonical Conversion Example**:
   Converting `20 SAR` to `YER` at an exchange rate of `140 YER/SAR`:

```text
Correct Conversion:
20 SAR × 140 YER/SAR = 2,800 YER

Forbidden Double-Conversion Result:
392,000 YER (resulting from applying rate twice)
```

3. **Multi-Currency Journal Balancing**: Journal entries containing lines in foreign currencies MUST compute base currency amounts using `JournalBaseAmountResolver` and satisfy balancing validation via `JournalBalanceValidator`.

---

## 5. Rounding & Precision
1. **High-Precision Rate Calculations**: Exchange rate calculations MUST maintain full precision during intermediate steps and apply exact monetary rounding only to final converted integer/decimal cents.
2. **Subledger Currency Consistency**: Accounts with explicit currency restrictions MUST reject transaction posting in non-matching currencies unless multi-currency posting is explicitly authorized.

---

## 6. Verification & Currency Test Requirements
1. **Exchange Rate Test Suite**: Unit and integration tests MUST verify currency calculations against real-world conversion pairs, zero rates, missing rates, inverted rates, and multi-currency journal entries.
