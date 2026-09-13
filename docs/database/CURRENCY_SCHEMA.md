# NEXABIZ ERP — CURRENCY SCHEMA SPECIFICATION (CURRENCY_SCHEMA.md)

## 1. Multi-Currency Governance Rules

As mandated by `.agents/rules/60-currency.md`:
1. **Scope Separation**:
   - **Global Currency Definition**: Standard ISO 4217 currencies catalog (`currencies`) is a **GLOBAL REFERENCE** entity shared across companies.
   - **Company Currency Configuration & Exchange Rates**: Company currency settings, active exchange rates (`currency_rates`), and historical rate logs (`currency_rate_history`) are **COMPANY-SCOPED** (`company_id`).
2. **Explicit Currency Attributes**: Every database table storing monetary amounts MUST include an associated non-nullable `currency_code` column alongside the monetary amount column.
3. **Dual Monetary Persistence**: For foreign currency transactions, tables MUST store both `transaction_amount` (in transaction currency) and `base_amount` (in company base currency), along with the `exchange_rate` applied.
4. **No Silent FX Fallback**: Operating without an explicit exchange rate when transaction currency $\neq$ base currency is strictly FORBIDDEN. A missing exchange rate MUST throw a `MissingExchangeRateException`. An exchange rate of `1.0` is strictly reserved for same-currency operations (when source currency equals target currency).
5. **Inventory Currency Rule**: Inventory master balances and cost layers MUST be maintained in the company's designated base currency (or designated inventory currency) to prevent valuation distortion.

---

## 2. Currency Domain Entities

### 2.1 Currencies Table (`currencies`)
Master catalog of global currency definitions (`code` ISO 4217, `name_ar`, `name_en`, `symbol`, `decimal_digits`, `is_default`).
- **Tenant Scope**: GLOBAL REFERENCE (Shared catalog across companies)

### 2.2 Currency Rates Table (`currency_rates`)
Active exchange rate table storing `company_id`, `from_currency`, `to_currency`, `rate`, `as_of_date`.
- **Tenant Scope**: COMPANY (`company_id`)
- **Key Constraints**: `(company_id, from_currency, to_currency)`

### 2.3 Currency Rate History Table (`currency_rate_history`)
Company-scoped historical log of foreign exchange rates (`company_id`, `currency_code`, `target_currency`, `rate`, `effective_date`). *Fixes legacy defect R2*.
- **Tenant Scope**: COMPANY (`company_id`)
- **Key Constraints**: `(company_id, currency_code, target_currency, effective_date)`

---

## 3. Explicit Exchange Rate Conversion & Conversion Formula

### 3.1 Rate Direction & Formula
NexaBiz standardizes exchange rates as direct multipliers to calculate Company Base Currency:
$$\text{Base Amount} = \text{Transaction Amount} \times \text{Exchange Rate}$$
Where:
- $\text{Transaction Amount}$ = Amount in transaction currency.
- $\text{Exchange Rate}$ = Direct multiplier rate $(\text{Base Currency} / \text{Transaction Currency})$.

### 3.2 Concrete Currency Conversion Example
- **Transaction Currency**: SAR (Saudi Riyal)
- **Company Base Currency**: YER (Yemeni Rial)
- **Transaction Amount**: $20 \text{ SAR}$
- **Exchange Rate**: $140 \text{ YER / SAR}$

$$\text{Base Amount} = 20 \text{ SAR} \times 140 \text{ YER/SAR} = 2800 \text{ YER}$$

### 3.3 Protection Against Double Conversion
To prevent accidental double conversion:
1. **Explicit Currency Tagging**: Every monetary calculation inspects the `currency_code` tag attached to the field.
2. **Base Currency Marker**: When an amount is stored as `base_debit` or `base_credit` in `journal_lines`, its currency is explicitly bound to `Company.currency_code`.
3. **Same-Currency Guard**: If `transaction_currency == base_currency`, `exchange_rate` is enforced as `1.0` and `base_amount = transaction_amount`, preventing chained re-multiplication. Missing exchange rates for foreign currencies throw `MissingExchangeRateException`.
