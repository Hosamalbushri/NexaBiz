# ADR-011: Sales Module

## Status

Accepted — 2026-08-13

## Context

The platform needs an operational Sales module that:

- Works offline-first
- Reuses Customers and Inventory catalog data without importing those modules
- Supports standalone operation and optional integrated accounting workflow
- Does **not** skip cash journals; **standalone cash/credit save** upserts via App `SaleLedgerPostingPort` (see ADR-008 amendment); **post** marks sale+journal posted

## Decision

1. **Own module** under `lib/modules/sales/` with Drift DB `sales_master` (tables `sales`, `sale_items`, `sale_payments`).
2. **Opaque FKs**: `customerId` / `productId` store Customer.uuid / Product.uuid.
3. **Cross-module access via ports** wired in App:
   - `SaleCustomerLookupPort` → Customers
   - `SaleProductCatalogPort` → Inventory + scan resolver
   - `SaleBarcodeCapture` → Inventory camera scanner
   - `SaleAccountingBridgePort` → Accounting mode + integration port
   - `SaleLedgerPostingPort` → local journal sync/void for standalone cash + credit sales
   - `SaleInventoryEffectPort` → NoOp until a stock ledger exists
4. **Numbering**: local `INV-######` allocator by default; App may later override with voucher-book allocation (`VoucherBookType.sales`).
5. **Lifecycle**: Unposted → Posted; Cancel voids journal + soft-deletes (reverses inventory when posted).
6. **Sync**: entity type `sale` via shared SyncManager.
7. **Money**: cent-rounded `double` math in `SaleCalculationService` / `SaleMoney` (matches Product.price).

## Consequences

- Sales appears in the Services launcher independently.
- Future POS / AR / reports can consume sale aggregates (`totalsForCustomer`, line snapshots).
- Inventory deduction remains opt-in through the effect port.
- No Sales → Accounting/Customers/Inventory imports.
