# PACKAGE ADMINISTRATION AD-09 — Company Settings

## Executive Summary

Phase AD-09 implements the centralized Company Settings Registry across 10 defined operational domains while preserving strict domain ownership and preventing duplicate sources of truth.

---

## 1. The 10 Settings Domains & Classification

| Domain | Scope | Domain Owner | Primary Settings Managed |
| :--- | :--- | :--- | :--- |
| **1. System Setup** | Company | System Setup | Fiscal year start, default language, locale, default currency |
| **2. Authentication** | Company | Auth / App Lock | Password complexity policy, session idle timeout, PIN/App Lock timeout |
| **3. Accounting** | Company | Accounting | Chart of Accounts root, tax rate defaults, accounting lock date, posting rules |
| **4. Inventory** | Company | Inventory | Costing method (FIFO/AVCO), negative stock allowance, low stock threshold alerts |
| **5. Cash Registers** | Company | Cash Registers | Shift opening float requirement, drawer limit threshold, auto-close policy |
| **6. Sales** | Company | Sales | Default price list, invoice number prefix, discount approval threshold |
| **7. Receipts & Payments** | Company | Receipts & Payments | Default payment methods, over-settlement allowance percentage, auto-allocation strategy |
| **8. Reports** | Company | Reports | Company logo header, PDF watermark string, default export file format |
| **9. Sync** | Company | Sync | Incremental sync interval, offline queue capacity, conflict resolution policy |
| **10. Administration** | Company | Administration | Audit log retention period, authorized IP range, active session cap per user |

> [!IMPORTANT]
> **Single Source of Truth Invariant**: The Administration module hosts the centralized settings registry UI and routing, but domain validation and default business rule logic reside exclusively within the respective domain modules (e.g. `inventory` costing method validation is owned by `InventoryCostingService`).

---

## 2. Implementation Summary

- **Registry & Scoping**: All settings are scoped to `company_id`.
- **Validation & Persistence**: Implemented `ManageAdminSettingsUseCase` validating domain setting schemas and persisting changes via `AdminRepository`.
- **Audit Logging**: Every settings update emits a `company_settings.updated` audit entry containing modified key lists.

---

## 3. Verification Gate

```text
GATE CERTIFICATION:
[x] All company settings classified across 10 canonical domains.
[x] Zero duplicate or conflicting sources of truth across module settings.
[x] Multi-tenant company scoping and audit trail logging verified.
```
