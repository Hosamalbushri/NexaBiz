# SA-01 — SALES FORENSIC DISCOVERY & ARCHITECTURE AUDIT REPORT

**Project:** NexaBiz ERP  
**Module:** Sales (`lib/modules/sales`, `lib/app/sales`, `test/modules/sales`)  
**Audit Date:** September 6, 2026  
**Status:** DISCOVERY COMPLETE  

---

## EXECUTIVE SUMMARY

A full forensic architecture audit of the NexaBiz **Sales Module** was performed. The audit inspected data models, database schemas (`sales_master` Drift DB), domain entities, services, use cases, port abstractions, application-layer adapters, presentation controllers, synchronization handlers, multi-tenant isolation, and test suite coverage.

The Sales module follows a clean hexagon/clean-architecture pattern where core domain logic is decoupled from external modules (Inventory, Accounting, Customers, Cash Registers) through strict interface ports (`lib/modules/sales/shared/domain/services/`). App-level adapters in `lib/app/sales/` wire these ports to real implementations.

Key structural findings, authoritative sources of truth, integration flows, state lifecycles, code duplications, system risks, and a prioritized remediation plan are detailed below.

---

## 1. ARCHITECTURE MAP & MODULE DEPENDENCIES

### Layered Architecture Structure

```
+-----------------------------------------------------------------------------------+
| PRESENTATION LAYER                                                                |
| - Pages: SalesHomePage, SalesListPage, SaleFormPage, SaleDetailsPage              |
| - Providers: salesListProvider, salesProvider, saleByIdProvider                   |
| - Controller: SaleComposerController (StateNotifier<SaleComposerState>)           |
+-----------------------------------------------------------------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------------+
| DOMAIN LAYER                                                                      |
| - Entities: Sale, SaleItem, SalePayment, SaleStatus, SaleSettlementType           |
| - Services: SaleCalculationService, SaleValidator, SaleWorkflowService            |
|             SaleQuantityMath, SaleCurrencyConverter, SaleMoney, DeviceSaleNumber  |
| - Use Cases: WatchSales, GetSaleById, CreateSale, UpdateSale, ConfirmSale,        |
|              CancelSale, DuplicateSale, DeleteSale                                |
| - Ports (Abstractions):                                                           |
|   * SaleCustomerLookupPort       * SaleProductCatalogPort                         |
|   * SaleInventoryEffectPort      * SaleLedgerPostingPort                          |
|   * SaleAccountingBridgePort     * SaleVoucherBookPort                            |
|   * SaleCurrencyPort             * SaleTreasuryAccountPort                        |
|   * SaleNumberAllocatorPort                                                       |
+-----------------------------------------------------------------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------------+
| DATA LAYER                                                                        |
| - Repositories: SaleRepositoryImpl, SaleNumberBlockStore                          |
| - Tables (Drift): Sales, SaleItems, SalePayments (in SalesDatabase)               |
| - Sync: SaleSyncHandler, SalesSyncRegistrar, SalesSyncBootstrap                   |
+-----------------------------------------------------------------------------------+
                                      |
                                      v
+-----------------------------------------------------------------------------------+
| APPLICATION INTEGRATION ADAPTERS (lib/app/sales/)                                 |
| - CustomersSaleLookupAdapter         -> CustomerRepository & AccountLinkPort      |
| - InventorySaleProductCatalogAdapter -> ProductRepository & ProductScanResolver   |
| - PerpetualSaleInventoryEffectAdapter -> DocumentPostingOrchestrator               |
| - AccountingSaleLedgerAdapter        -> JournalPostingService & AccountRepository   |
| - AccountingSaleTreasuryAdapter      -> CashRegisterRepository & AccountRepository |
| - AccountingSaleVoucherBookAdapter   -> VoucherBookRepository & BlockStore        |
| - AccountingSaleCurrencyAdapter      -> CurrencyRateRepository                    |
| - AccountingSaleBridgeAdapter        -> AccountingIntegrationPort                 |
+-----------------------------------------------------------------------------------+
```

### Dependency Graph

* **`lib/modules/sales` Dependencies:**
  * `lib/core` (`database/encrypted_drift_connection`, `permissions/permission_guard`, `tenancy/tenant_context`, `utils/business_date`, `utils/journal_money`, `utils/id_generator`)
  * `lib/modules/sync` (`SyncQueue`, `SyncOperation`, `ConflictResolver`, `SyncEntityHandler`)
* **`lib/app/sales` Adapter Dependencies:**
  * `lib/modules/accounting` (`DocumentPostingOrchestrator`, `JournalPostingService`, `AccountRepository`, `CurrencyRateRepository`, `VoucherBookRepository`)
  * `lib/modules/inventory` (`StockMovementsRepository`, `ProductRepository`, `ProductScanResolver`)
  * `lib/modules/customers` (`CustomerRepository`, `CustomerAccountLinkPort`)
  * `lib/modules/cash_registers` (`CashRegisterRepository`, `DefaultCashRegisterResolver`)
  * `lib/modules/system_setup` (`CompanyInitializationRepository`, `AccountingScopeResolver`)

---

## 2. SOURCES OF TRUTH & DATA OWNERSHIP

| Data Element | Authoritative Source of Truth | Notes & Findings |
| :--- | :--- | :--- |
| **Sale Document & Header** | Drift Table `sales` | Managed by `SaleRepositoryImpl`. |
| **Sale Status** | `sales.sale_status` (`'unposted'` / `'posted'`) | Domain enum `SaleStatus` (unposted, posted). Default DB string `'draft'` maps to `unposted`. |
| **Customer** | Customers Module (`CustomerRepository`) | Sales holds snapshot (`customer_id`, `customer_code`, `customer_name`, `customer_account_id`). Walk-in sales store free-text name. |
| **Warehouse** | Inventory Module (`Warehouse`) | Sales holds snapshot `sales.warehouse_id`. Validation enforces presence before save. |
| **Product & Unit Price** | Inventory Module (`ProductRepository`) | Sales holds snapshot (`product_id`, `product_name`, `product_code`, `barcode`, `base_unit_price`, `unit_price`, `pack_size`). |
| **Quantity & Pack Math** | `sale_items` table & `SaleQuantityMath` | Stores `quantity` (effective billing), `main_quantity`, `sub_quantity`, and `pack_size`. |
| **Totals & Tax** | `SaleCalculationService` & `SaleMoney` | Pure domain calculation. Subtotal, line discount, header discount, and tax redistribution computed strictly in cents integer math. |
| **Currency & FX Rate** | `sales.currency_code`, `base_currency_code`, `exchange_rate` | Snapshot taken at save time via `SaleCurrencyConverter` and `AccountingSaleCurrencyAdapter`. |
| **Inventory Cost & COGS** | Inventory Module / `CostLayerServiceImpl` | **NOT stored in Sales**. Sales passes quantity and movement lines to `DocumentPostingOrchestrator`. Cost is resolved dynamically from FIFO cost layers. |
| **Stock Movement** | `StockMovementsRepository` | Created on post via `PerpetualSaleInventoryEffectAdapter`. |
| **Journal Entries** | Accounting Module (`DocumentPostingOrchestrator` / `JournalPostingService`) | Created on post. Dual revenue & COGS entries generated in perpetual mode. |
| **Customer Receivable / Cash** | Accounting Ledger (`AccountRepository`) | Linked to `customer_account_id` (AR) or `cash_account_id` (Cash Box/Register). |

---

## 3. DOCUMENT LIFECYCLE & STATE TRANSITIONS

```
            [ Draft / Unposted ]
                     |
        +------------+------------+
        |                         |
  (ConfirmSale / Post)     (CancelSale)
        |                         |
        v                         v
    [ Posted ]              [ Cancelled / Soft-Deleted ]
        |
  (CancelSale)
        |
        v
[ Cancelled / Soft-Deleted ]
```

### Existing Statuses

* `SaleStatus.unposted`: Editable document. Has no stock movement or accounting journal effects.
* `SaleStatus.posted`: Immutable document. Triggers inventory deduction (issue movement), FIFO costing, and journal posting.

### Lifecycle Rules & Invariants

1. **Posting (`ConfirmSale`):** Allowed only when `saleStatus == unposted`. Enforces permission `sales.documents.post` and requires valid inventory effect setup.
2. **Editing (`UpdateSale`):** Allowed only when `saleStatus == unposted`. Attempting to update a posted sale throws `SaleException.postedImmutable`.
3. **Cancellation (`CancelSale`):** Allowed for both `unposted` and `posted` sales. Voids accounting entries and reverses stock movements via `_orchestrator.unpostSaleInvoice`.
4. **Completion (`CompleteSale`):** **Deprecated**. Invoking `CompleteSale` throws `SaleException.invalidStatusTransition`.

### Flaws & State Vulnerabilities Found

* **Cancellation Status Anomaly:** `CancelSale` performs soft deletion (`deletedAt = now`) and triggers stock/ledger reversal, but does **not** update `saleStatus` in the database to `'cancelled'`. The DB row retains `sale_status = 'posted'` with `deletedAt != null`.
* **Settlement Type Pre-fill Inconsistency:** In `SaleComposerState`, setting `settlementType = cash` forces `paidAmount = total`, whereas `credit` forces `paidAmount = 0`. Partial cash payments on credit invoices require manual payment record handling.

---

## 4. MULTI-COMPANY & TENANT ISOLATION

* **Database Scoping:** The `sales` table contains `company_id` (indexed). `SaleRepositoryImpl` filters every query with `t.companyId.equals(_currentCompanyId)`.
* **Database Encryption & Splitting:** Database connections use `tenantScopedName('sales_master', sessionCompanyId)`.
* **Account & Register Isolation:**
  * Cash account dropdown uses `AccountingSaleTreasuryAdapter`, which filters by `companyId` via `AccountingScopeResolver`.
  * Setup integration (`registerSalesSetup`) enforces `CrossCompanyAccountBindingException` if an account from Company B is assigned to Company A.

---

## 5. INVENTORY INTEGRATION

* **Posting Flow:**
  1. `ConfirmSale` calls `PerpetualSaleInventoryEffectAdapter.onConfirmed(sale)`.
  2. Builds `StockMovementLine` instances for items with `quantity > 0`.
  3. Invokes `_stockMovementsRepository.saveMovementLines(movementUuid: sale.uuid, movementType: 'issue')`.
  4. Delegates posting to `DocumentPostingOrchestrator.postSaleInvoice(sale: postingData, docRef: docRef)`.
  5. `DocumentPostingOrchestrator` consumes FIFO stock cost layers, updates inventory balances, and generates COGS journal entries.
  6. If stock is insufficient, `DocumentPostingOrchestrator` returns an `OrchestrationFailure`, triggering a database status rollback in Sales to keep the document `unposted` and editable.

* **Audit Finding:** Sales does **not** calculate inventory cost independently or modify stock directly. Stock delegation is cleanly isolated via `SaleInventoryEffectPort`.

---

## 6. ACCOUNTING INTEGRATION

### Standalone vs. Perpetual Mode Accounting

1. **Perpetual Inventory Mode (Default):**
   * Handled by `DocumentPostingOrchestrator`.
   * Generates two integrated accounting vouchers:
     * **Sales Voucher:** Debit Cash Box / AR Account, Credit Revenue Account, Credit Tax Payable.
     * **COGS Voucher:** Debit COGS Expense Account, Credit Inventory Asset Account (calculated at FIFO cost).

2. **Standalone Mode (Manual / Non-Perpetual):**
   * Handled by `AccountingSaleLedgerAdapter`.
   * Posts single journal entry to `JournalPostingService`:
     * **Debit:** Cash Account (`cashAccountId`) or Customer Account (`customerAccountId`).
     * **Debit:** Sales Discount Account (`AccountRole.discount` / `AccountRole.cogs`) if discount > 0.
     * **Credit:** Sales Revenue Account (`AccountRole.revenue`).
     * **Credit:** Tax Payable Account (`AccountRole.payable`) if tax > 0.

---

## 7. DUPLICATION & CODE SMELL AUDIT

1. **Duplicate Calculation Logic:**
   * Pure rounding and math are centralized in `SaleCalculationService` and `SaleMoney`.
   * However, `SaleComposerState.calculateSummary()` replicates draft preparation logic, and `SaleRepositoryImpl` recalculates summary inside `insert()` and `update()`.
2. **Deprecated Code Preservation:**
   * `CompleteSale` use case is retained in `sale_usecases.dart` and `sale_providers.dart` solely for signature compatibility, throwing an exception when called.
3. **Redundant Fallback in Treasury Adapter:**
   * `AccountingSaleTreasuryAdapter` contains fallback logic for when `cashRegisterRepository` is null, generating synthetic `CashRegister` instances from raw cash accounts.

---

## 8. TEST SUITE AUDIT

### Existing Sales Tests (`test/modules/sales/`)

1. `sale_warehouse_test.dart`: 3 tests verifying `warehouseId` state in `SaleComposerState` and `toDraft()`.
2. `sales_setup_integration_test.dart`: 5 tests verifying setup registration, account binding, missing account invariant, and multi-tenant cross-company account rejection.

### Test Audit Findings & Missing Scenarios

| Area | Status | Missing Scenarios & Weaknesses |
| :--- | :--- | :--- |
| **SaleCalculationService** | ❌ Missing | No dedicated unit tests for percentage/fixed line discounts, header discounts, tax distribution, and cent rounding precision. |
| **SaleValidator** | ❌ Missing | No unit tests for price below catalog floor, missing warehouse, invalid tax rate, or missing customer account. |
| **ConfirmSale / CancelSale** | ❌ Missing | No unit tests for stock failure rollback, double-posting prevention, or journal voiding. |
| **SaleRepositoryImpl** | ❌ Missing | No unit tests for database transactions, keyset pagination, customer totals aggregation, or soft deletion. |
| **Sync Integration** | ❌ Missing | No unit tests for `SaleSyncHandler` conflict resolution, remote payload application, or version bump idempotency. |

---

## 9. RECOMMENDED REMEDIATION ORDER

Before proceeding with future architectural enhancement packages, the following remediation steps are recommended:

1. **Fix Cancellation Status Tracking:**
   Update `CancelSale` to explicitly set `saleStatus = SaleStatus.unposted` or record explicit cancellation status prior to soft deletion.
2. **Expand Sales Unit & Integration Test Suite:**
   Create unit tests covering `SaleCalculationService`, `SaleValidator`, `ConfirmSale` rollback semantics, and `SaleSyncHandler` conflict handling.
3. **Clean Up Deprecated Legacy Code:**
   Safely remove `CompleteSale` and eliminate dead fallback code paths in `AccountingSaleTreasuryAdapter`.
4. **Standardize UI Form Components:**
   Align transaction header cards, option selectors, and sticky summary footers in `sale_form_page.dart` with canonical core widgets.

---

## AUDIT COMPLETION STATUS

**DISCOVERY COMPLETE**
