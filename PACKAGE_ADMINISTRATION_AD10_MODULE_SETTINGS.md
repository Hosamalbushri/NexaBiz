# PACKAGE ADMINISTRATION AD-10 — Module Settings

## Executive Summary

Phase AD-10 performs an audit across all 11 NexaBiz modules to map configuration settings, establish explicit module domain ownership, define persistence and sync behaviors, and eliminate duplicate or conflicting setting implementations.

---

## 1. 11-Module Setting Governance Matrix

| # | Module | Setting Identifier | Domain Owner | Persistence Strategy | Validation Location | Admin UI Surface | Sync Behavior |
| :---: | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **1** | **Accounting** | `lock_date`, `auto_post_journal` | Accounting | Drift DB / Backend SQL | `AccountingPolicyEngine` | Admin > Settings > Accounting | Pushed on mutation |
| **2** | **Cash Registers** | `opening_float_required`, `max_float` | Cash Registers | Drift DB / Local Store | `CashRegisterConfigGuard` | Admin > Settings > Registers | Synchronized |
| **3** | **Customers** | `credit_limit_check`, `tax_exempt_default` | Customers | Drift DB / Backend SQL | `CustomerValidationService` | Admin > Settings > Customers | Synchronized |
| **4** | **Inventory** | `costing_method` (FIFO/AVCO), `neg_stock` | Inventory | Drift DB / Backend SQL | `InventoryCostingEngine` | Admin > Settings > Inventory | Pushed on mutation |
| **5** | **Sales** | `allow_discount_override`, `default_pricelist` | Sales | Drift DB / Local Store | `SalesPolicyEngine` | Admin > Settings > Sales | Synchronized |
| **6** | **Receipts & Payments** | `auto_allocation`, `max_overpay_pct` | Receipts & Payments | Drift DB / Backend SQL | `SettlementPolicyEngine` | Admin > Settings > Receipts | Pushed on mutation |
| **7** | **Reports** | `pdf_header`, `watermark_text` | Reports | Local Storage / SharedPrefs | `ReportRenderer` | Admin > Settings > Reports | Local / Config Sync |
| **8** | **Sync** | `sync_interval_sec`, `max_batch_size` | Sync Engine | SharedPrefs / Drift DB | `SyncConfigValidator` | Admin > Settings > Sync | System level |
| **9** | **System Setup** | `fiscal_start`, `primary_locale` | System Setup | Drift DB / Backend SQL | `SystemSetupValidator` | Admin > Settings > System | Pushed on mutation |
| **10** | **Authentication** | `pass_min_len`, `max_attempts` | Authentication | Backend SQL / Secure Storage | `AuthPolicyEngine` | Admin > Settings > Security | Server enforced |
| **11** | **App Lock** | `auto_lock_timeout_sec`, `biometric_opt` | App Lock | Secure Storage (SS) | `AppLockConfigGuard` | Admin > Settings > App Lock | Local device |

---

## 2. Remediation & Duplicate Removal

- **Audit Finding**: Previously, inventory costing settings were duplicated in both `lib/modules/administration/shared/data/admin_api_repository.dart` and `lib/modules/inventory/domain/services/costing_service.dart`.
- **Remediation**: All domain logic and validation for inventory costing now route exclusively through `InventoryCostingEngine`. Administration serves purely as an input view layer.

---

## 3. Verification Gate

```text
GATE CERTIFICATION:
[x] All 11 modules audited and domain setting owners mapped.
[x] Duplicate setting implementations eliminated across all modules.
[x] Single authoritative source of truth verified for every system setting.
```
