# SA-10 — Sales UI, UX & Component Consolidation Audit

## Overview
This document delivers a comprehensive architectural audit and consolidation report of the Sales module UI and UX components. It details how the Sales interface adheres to canonical design system standards (`ModuleListScaffold`, `AppDocumentMetaChip`, `AppDocumentOptionCard`, `AppFilterSheet`, `AppErrorState`, `AppAmountField`), enforces explicit warehouse selection, displays non-authoritative COGS previews, and eliminates redundant custom UI widgets.

---

## 1. Sale Form Architecture & Exposed Fields
The canonical Sales invoice creation/edit form (`SaleFormPage`) exposes all required transaction fields:
- **Customer:** Linked customer account selector (`SaleCustomerSearchField`), supporting walk-in and credit accounts with explicitCoA linking validation.
- **Warehouse:** Explicit warehouse selection (`onWarehouseChanged`). Fallback or hidden warehouses are strictly prohibited.
- **Document Date:** `AppDocumentMetaChip` with date picker trigger (`_pickDate`).
- **Currency & FX:** `SaleCurrencyRef` dropdown and exchange rate snapshot input.
- **Voucher Book / Document Number:** `AppDocumentMetaChip` showing device/voucher numbering.
- **Line Items:** `SaleProductsTable` exposing product, main/sub quantities, unit price, catalog minimum price guards, line discounts, and line totals.
- **Financial Summary:** `SaleStickySummary` displaying subtotal, item discount total, document discount, tax amount, grand total, and payment status.

---

## 2. Explicit Warehouse Selection Guarantee
- `SaleComposerState` initializes `warehouseId` as `null` by default.
- `canSave` evaluates `warehouseId != null && warehouseId.isNotEmpty`.
- The UI forces explicit user selection or explicit company default assignment. Fallback or silent global warehouse defaults are eliminated.

---

## 3. Non-Authoritative Inventory Cost & COGS Preview
- For authorized users, `SaleDetailsPage` and preview widgets expose calculated cost, costing method (FIFO/LIFO/WAC), and COGS previews.
- **UI Non-Authoritative Rule:** COGS previews are strictly labelled as calculated previews. The UI never computes or persists authoritative inventory cost layers; cost layer evaluation is executed solely by the server/domain `CostLayerService`.

---

## 4. Canonical Core Component Reuse Inventory
The Sales module reuses canonical application widgets across all pages:

| Component Category | Canonical Core Widget Used | Sales Module Usage |
| :--- | :--- | :--- |
| Page Scaffolding | `ModuleListScaffold`, `CustomAppBar` | `SalesListPage`, `SaleFormPage`, `SaleDetailsPage` |
| Navigation Guard | `UnsavedChangesScope` | `SaleFormPage` (unsaved draft guard) |
| Filtering & Search | `AppFilterSheet`, `AppSearchBar` | `SalesListPage` (status, settlement, query filtering) |
| Meta Data Chips | `AppDocumentMetaChip` | Invoice number, date, voucher book, warehouse badges |
| Option Cards | `AppDocumentOptionCard` | Settlement type switcher (Cash / Credit) |
| Amount Input | `AppAmountField` | Discount values, unit prices, paid amounts |
| Status Display | `SaleStatusBadge`, `SaleNumberText` | Status indicators and formatted document numbers |
| Error & Empty State | `AppErrorState`, `AppEmptyState` | List loading errors and empty invoice states |
| Autocomplete & Pickers | `SaleCustomerSearchField`, `VoucherBookSelector`, `CashAccountSelector` | Customer, voucher book, and cash register account selection |

---

## 5. Responsive Design, RTL & Localization Compliance
- **Responsive Layout:** Responsive `ListView` insets (`AppConstants.pageInsets`) adapt across mobile, tablet, and desktop viewports.
- **RTL & Localization:** All user-facing strings consume `AppLocalizations` (`l10n`), supporting full Arabic RTL layout mirroring.
- **Accessibility:** Touch targets meet standard sizes (minimum 44x44 dp) with semantic accessibility hints on interactive chips and icon buttons.

---

## 6. Posted Document View Compliance (`SaleDetailsPage`)
The posted sale details page clearly exposes:
- **Document Status:** `SaleStatusBadge` (Unposted / Posted / Cancelled).
- **Party Context:** Customer name, customer CoA account, walk-in status.
- **Location Context:** Explicit warehouse name and warehouse ID.
- **Monetary Totals:** Document currency, subtotal, discounts, tax, grand total, paid amount, remaining balance.
- **Settlement & Payment:** Payment method breakdown (Cash / Card / Bank / Credit) and linked Cash Box account.
- **COGS Preview:** Authorized COGS breakdown and consumed inventory layer references.
- **Return Status:** Remaining returnable quantity per line item.
