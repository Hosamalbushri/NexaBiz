# 70 — LOCALIZATION, RTL & FORMATTING GOVERNANCE

## 1. Localization Philosophy
1. **Separation of Concerns**: Business domain logic, database queries, entity status keys, error codes, and accounting calculations MUST be completely independent of localized display text.
2. **Canonical Translation System**: All user-facing text strings MUST be resolved through the canonical Flutter localization system (`L10n` / `AppLocalizations`). Hardcoded UI string literals in presentation widgets are FORBIDDEN.

---

## 2. Domain Errors vs. Presentation Mapping
1. **Domain Error Independence**: Domain errors and validation failures MUST throw typed domain exception classes or return domain error enums (e.g., `PeriodLockedException`, `InsufficientStockError`, `MissingExchangeRateError`). Domain errors MUST NOT contain localized human-readable text strings.
2. **Presentation Error Resolution**: Presentation controllers and UI error mappers MUST catch domain exceptions and map domain error enums to localized translation keys for display to the user.

---

## 3. Directionality & Layout (RTL / LTR)
1. **Bi-Directional First**: NexaBiz natively supports Right-to-Left (RTL, e.g., Arabic) and Left-to-Right (LTR, e.g., English) layouts.
2. **Directional Padding & Alignment**: UI components MUST use direction-aware alignment primitives (e.g., `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextDirection`) instead of hardcoded `EdgeInsets.left` or `EdgeInsets.right`.

---

## 4. Number & Currency Formatting
1. **Centralized Formatting Engine**: Number formatting (decimal separators, thousand separators, digit grouping) and monetary currency display MUST route through centralized locale-aware formatters.
2. **Arabic Digit Formatting**: System locales supporting Eastern Arabic numerals MUST handle digit rendering presentationally without altering underlying ASCII string numeric representations stored in the database.

---

## 5. Accounting & Domain Terminology
1. **Standard Financial Terms**: Financial and accounting translations (e.g., General Ledger, Journal Entry, Trial Balance, Accounts Receivable) MUST use standardized, industry-accepted accounting terminology across supported languages.
2. **Translation Fallbacks**: If a specific translation key is missing in a secondary locale, the system MUST fall back gracefully to the primary system language key rather than displaying raw code symbols or crashing.

---

## 6. Verification & Testing
1. **Localization Linting**: Static analysis rules MUST flag unlocalized hardcoded text strings in presentation widgets.
2. **Layout Testing**: Presentation widgets MUST be verified under both RTL and LTR viewports to ensure zero visual clipping or layout overflows.
