# SA-05 — Sales Inventory Consumption & COGS Integrity

## Overview
This document specifies the integration rules governing Sales inventory stock consumption, valuation method execution (FIFO, LIFO, WAC), multi-warehouse layer isolation, persistent cost layer consumption tracking, and strict negative stock rejection in the NexaBiz ERP system.

---

## 1. Authoritative Sales Inventory Flow
Sales transactions adhere strictly to the following domain pipeline:

```
Sale Document
  ↓
Warehouse Selection & Validation
  ↓
Stock Availability & Layer Check
  ↓
Inventory Posting (Stock Movement Issue)
  ↓
Costing Valuation Engine (FIFO / LIFO / WAC)
  ↓
Cost Layer Consumption & Remaining Qty Update
  ↓
Stock Quantity Decrease
  ↓
COGS Calculation & Persistence
  ↓
Accounting Ledger Journal Entry
```

---

## 2. No UI Costing Invariant
- **Rule:** The user interface (UI) must **NEVER** determine, calculate, or pass authoritative unit cost, COGS, cost layer, or stock availability.
- All costing computations, stock checks, and layer consumptions are executed strictly by `CostLayerService` and `PostingCoordinatorPort` on the domain/server layer.

---

## 3. Valuation Methods (FIFO, LIFO, WAC)

### FIFO (First-In, First-Out)
- Active when product / company inventory valuation method is `CostValuationMethod.fifo`.
- Consumes cost layers ordered by `receivedDate ASC` (oldest receipt layer consumed first).

### LIFO (Last-In, First-Out)
- Active when product / company inventory valuation method is `CostValuationMethod.lifo`.
- Consumes cost layers ordered by `receivedDate DESC` (newest receipt layer consumed first).

### WAC (Weighted Average Cost)
- Active when product / company inventory valuation method is `CostValuationMethod.weightedAverage`.
- Calculates current weighted average cost per unit across open active layers for the item and warehouse:
  $$\text{WAC} = \frac{\sum (\text{Remaining Qty} \times \text{Unit Cost})}{\sum \text{Remaining Qty}}$$
- Consumes quantities proportionally across layers using the calculated weighted average unit cost.

---

## 4. Cost Consumption Persistence & Historical Reproducibility
- Every consumption generated during sales posting is persisted as an immutable record in the `inventory_cost_consumptions` table:
  - `uuid`: Unique consumption identifier.
  - `layerUuid`: Reference to the source cost layer (`inventory_cost_layers`).
  - `issueLineUuid`: Reference to the sales issue line item.
  - `movementType`: 'issue'.
  - `consumedQty`: Quantity consumed from the layer.
  - `unitCost`: Unit cost applied.
  - `totalCost`: Total cost value ($\text{consumedQty} \times \text{unitCost}$).
  - `createdAt`: Timestamp.
  - `companyId`: Tenant scope.
- **Historical Reproducibility:** Historical COGS is never re-calculated on historical transactions. The persisted `inventory_cost_consumptions` records guarantee exact reproducibility of past sales COGS.

---

## 5. Negative Stock Rejection Rules
- **Rule:** If available stock in active layers is insufficient to satisfy the requested sale quantity (`isShortage == true`), the Inventory layer returns `PostStockShortage`.
- Sales posting **MUST FAIL IMMEDIATELY** and throw `SaleException.insufficientStock`.
- System **MUST NOT**:
  1. Create negative stock quantities.
  2. Post COGS with guessed or estimated costs.
  3. Proceed with accounting journal entries after a stock failure.

---

## 6. Multi-Warehouse Layer Isolation
- Cost layers are strictly scoped by `warehouseId` (`tbl.warehouseId.equals(warehouseId)`).
- Stock in **Warehouse A** will **NEVER** consume or touch cost layers belonging to **Warehouse B**.
- Every sale line item explicitly identifies its target `warehouseId`.

---

## 7. Concurrency, Idempotency & Reversal

### Concurrency
- Layer updates use atomic conditional queries (`remainingQty.isBiggerOrEqualValue(takeQty)`) within database transactions. Concurrency conflicts trigger controlled retries or transaction rollbacks.

### Duplicate Posting (Idempotency)
- `CostLayerService` checks existing consumptions by `issueLineUuid`. Re-posting an already processed line returns existing consumption records without re-consuming layers.

### Returns & Reversal
- Unposting or cancelling a sale invokes `reverseConsumptions(issueLineUuid)`, which restores consumed quantities back to their respective cost layers (`remainingQty = remainingQty + consumedQty`) and removes consumption records cleanly.

---

## 8. Verification Matrix
Verified via `test/modules/sales/sales_inventory_cogs_test.dart` covering:
1. FIFO layer consumption (oldest layer first).
2. LIFO layer consumption (newest layer first).
3. WAC layer valuation & consumption.
4. Partial layer consumption.
5. Multi-layer consumption across multiple receipts.
6. Insufficient stock failure & transaction block.
7. Multi-warehouse layer isolation.
8. Duplicate posting idempotency guard.
9. Reversal & return handling (`reverseConsumptions`).
