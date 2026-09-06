# RP-09 — RECEIPTS & PAYMENTS UI & COMPONENT CONSOLIDATION SPECIFICATION REPORT

## EXECUTIVE SUMMARY
This audit report documents the consolidation of the Receipts & Payments UI around the canonical NexaBiz design system. It details the input fields, interactive allocation interface, multi-currency display standards, canonical widget reuse matrix, non-authoritative UI principles, and responsive/RTL layout compliance.

---

## 1. FORM SPECIFICATIONS

### Receipt Form Fields
- **Customer / Counterparty Person:** Autocomplete selector (`RpCustomerSearchField`).
- **Amount & Currency:** Double-precision numeric input (`AppAmountField`) + Currency selector (`AppFilterSheet`).
- **Payment Method:** Dropdown selection (Cash, Bank Transfer, Check, Card).
- **Cash Register / Bank Account:** Explicit account selector (`RpCashAccountDropdown`).
- **Date & Reference:** Date picker widget (`showDatePicker`) + Document reference text field.
- **Allocations:** Line table with credit allocation inputs (`RpEntryLinesTable`).
- **Notes:** Multi-line description field (`AppTextField`).

### Payment Form Fields
- **Supplier / Counterparty Person:** Autocomplete selector (`RpCustomerSearchField` / `RpAccountSearchField`).
- **Amount & Currency:** Double-precision numeric input (`AppAmountField`) + Currency selector.
- **Payment Method:** Dropdown selection (Cash, Bank Transfer, Check, Card).
- **Source Account / Cash Register:** Explicit account selector (`RpCashAccountDropdown`).
- **Date & Reference:** Date picker widget + Document reference text field.
- **Allocations:** Line table with debit allocation inputs (`RpEntryLinesTable`).
- **Notes:** Multi-line description field (`AppTextField`).

---

## 2. INTERACTIVE ALLOCATION UI SPECIFICATION

| Column | Description | Real-Time Client Validation Rule |
| :--- | :--- | :--- |
| **Document** | Target invoice or voucher document reference. | Required non-empty string. |
| **Outstanding** | Remaining un-settled balance on the document. | Informational; fetched from backend. |
| **Allocated** | Amount allocated by current receipt/payment. | $0 < \text{Allocated} \le \text{Outstanding}$. |
| **Remaining** | Net outstanding post-allocation ($\text{Outstanding} - \text{Allocated}$). | Must be $\ge 0$. |

---

## 3. CURRENCY & FX TRANSPARENCY SPECIFICATION

The UI MUST explicitly show all 3 currency layers:
1. **Transaction Amount & Currency:** e.g., `1,000 USD`.
2. **Exchange Rate:** e.g., `1 USD = 3.75 SAR`.
3. **Base Currency Equivalent:** e.g., `3,750 SAR`.

No implicit or hidden FX conversions are allowed anywhere in the UI.

---

## 4. CANONICAL DESIGN SYSTEM REUSE MATRIX

| Component Class | Canonical Core Widget Used | Status |
| :--- | :--- | :--- |
| **Page Scaffolding** | `AppResponsiveScaffold`, `CustomAppBar` | Fully Standardized |
| **Autocomplete Fields** | `AppAsyncAutocompleteField`, `RpCustomerSearchField` | Fully Standardized |
| **Search Toolbar & Bar** | `AppSearchToolbar`, `AppSearchBar` | Fully Standardized |
| **Form Layout Pattern** | `AppFormPagePattern`, `AppBottomActions` | Fully Standardized |
| **List Page Pattern** | `AppListPagePattern` | Fully Standardized |
| **Detail Page Pattern** | `AppDetailPagePattern`, `AppDetailInfoRow` | Fully Standardized |
| **State Feedback** | `AppLoading`, `AppErrorState`, `AppEmptyState` | Fully Standardized |
| **Form Action Buttons** | `AppButton`, `AppBottomActions` | Fully Standardized |

---

## 5. UI NON-AUTHORITY PRINCIPLE

> [!IMPORTANT]
> The UI is purely a presentation and data-entry layer.
> The UI NEVER maintains authoritative financial state for account balances, allocation limits, foreign exchange rates, accounting journals, or cash balances.
> All authoritative calculations and invariant checks are performed strictly by domain entities and services.

---

## 6. RESPONSIVE & RTL AUDIT

- **RTL / Localization Support:** Fully integrated with `AppLocalizations` (Arabic `ar` & English `en`), using directional layout widgets (`AlignmentDirectional`, `EdgeInsetsDirectional`).
- **Screen Breakpoints:**
  - **Desktop / Tablet:** Wide multi-column forms using `AppResponsiveScaffold`.
  - **Mobile / Narrow Widths:** Single-column layout with sticky bottom action buttons (`AppBottomActions`).
