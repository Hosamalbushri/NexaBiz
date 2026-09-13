# NEXABIZ ERP — INVENTORY SCHEMA SPECIFICATION (INVENTORY_SCHEMA.md)

## 1. Executive Summary & Accepted Behavioral Truth

This document defines the canonical database persistence model for the NexaBiz Inventory Module based on accepted Phase 5 inventory remediation rules:

1. **Draft Movement $\neq$ Authoritative Inventory State**: Unposted draft documents record user intent only, produce zero stock effects, zero cost layer mutations, and zero GL postings.
2. **Posting Boundary**: Posting is the single authoritative boundary validating quantity, cost, currency/rate, and period constraints before applying effects.
3. **No Negative Stock**: If posting would result in a negative stock quantity or invalid cost balance, `POST MUST FAIL`.
4. **Independent Costing per Product (WAC vs FIFO)**: Each product independently uses **WAC** (Weighted Average Cost) or **FIFO** (First-In, First-Out). LIFO is strictly prohibited.
5. **Costing Method Change Rule**: A product's costing method can change ONLY when:
   - All relevant transactions/entries are posted/resolved;
   - Product stock balance is zero;
   - No unresolved effects remain.
6. **Unpost Semantics**: Unposting removes posted inventory effects, reverts document status to `DRAFT`, does NOT create a reversing journal, considers relevant later inventory dependencies (unrelated non-inventory operations do not automatically block), and deterministically recalculates stock balances and cost layers from remaining valid posted history.
7. **Sales Return Cost**: Valuation MUST use the **CURRENT PRODUCT COST AT THE MOMENT THE RETURN IS POSTED** (NOT the historical sale cost).

---

## 2. Forensic Inventory Authority Analysis

### Forensic Question 1
> If `product_warehouse_stocks` is deleted, can authoritative stock state be reconstructed?
- **ANSWER**: **YES.** `product_warehouse_stocks` is a derived read projection. Authoritative stock balance per product per warehouse is reconstructed by calculating the net quantity sum of all valid posted movements in `stock_movement_ledgers`.

### Forensic Question 2
> If `stock_movement_ledgers` is deleted, can authoritative stock history be reconstructed?
- **ANSWER**: **NO.** `stock_movement_ledgers` is the immutable, authoritative source of truth for physical stock movement history. If deleted, historical stock movements cannot be recovered.

---

## 3. Detailed Entity & Lifecycle Mapping

```text
Draft Document (Intent, Editable, No Stock/Cost Effect)
       ↓
[ POST OPERATION (Atomic Validation & Transaction Boundary) ]
       ├─► Stock Movement Ledger (Authoritative Physical Stock Ledger)
       │    └─► 1 Document Line -> 0, 1, or N Stock Movement Ledger Effects
       ├─► Costing State:
       │    ├── WAC: Recalculates product average cost (Derived/Rebuildable State)
       │    └── FIFO: Inserts Inbound Cost Layer or Records Consumption Trace
       ├─► Derived Stock Balance Projection (product_warehouse_stocks)
       └─► Accounting Effect (GL Journal Entry via JournalPostingService)
       ↓
[ UNPOST OPERATION ]
       ├─► Removes Stock Movement Ledger & Cost Consumption entries for ALL lines
       ├─► Reverts document status to DRAFT
       ├─► Validates later inventory dependencies (Unrelated non-inventory operations do not block)
       └─► Deterministically recalculates stock balances & cost layers from valid remaining history
```

---

## 4. Costing Method Specifications

### 4.1 WAC (Weighted Average Cost)
For products configured with `costing_method = 'WAC'`:
$$\text{New WAC} = \frac{(\text{Current OnHand Qty} \times \text{Current WAC}) + (\text{Inbound Qty} \times \text{Inbound Unit Cost})}{\text{Current OnHand Qty} + \text{Inbound Qty}}$$
- Product average cost is a derived state recalculated upon inbound posting.
- Outbound movements value COGS using the current WAC average cost.

### 4.2 FIFO (First-In, First-Out)
For products configured with `costing_method = 'FIFO'`:
- Inbound movements create a new row in `inventory_cost_layers`.
- Outbound movements consume remaining quantity from the oldest active cost layer (`remaining_qty > 0`) in chronological order of posting date, creating traceable records in `inventory_cost_consumptions`. One document line may produce multiple FIFO consumption trace records if it spans multiple cost layers.

---

## 5. Inventory Unpost & Deterministic Recalculation Flow

When a posted inventory-affecting document is unposted:
1. **Remove Posting Effects**: All inventory effects belonging to ALL lines of the document are removed from `stock_movement_ledgers` and `inventory_cost_consumptions`.
2. **Revert Document Status**: The document status becomes editable `DRAFT`.
3. **No Reversing Journal**: No reversing journal entry is created by the inventory unpost operation itself.
4. **Dependency Verification**: Relevant later inventory dependencies are considered (e.g. unposting an inbound receipt that supplied stock for a later outbound issue). Unrelated non-inventory operations (such as invoice payment settlements) do NOT automatically block inventory unpost.
5. **Deterministic Recalculation**: Authoritative stock balances and cost layers are recalculated from scratch using only the remaining valid posted history.
6. **Repost Operation**: When reposted, the document recalculates the new quantity and cost state again based on active inventory state at reposting time.

---

## 6. Sales Return Costing Rule

When a Sales Return document is posted:
- Returned items are valued using the **CURRENT PRODUCT COST AT THE MOMENT THE RETURN IS POSTED**.
- It is NOT copied from the historical sale invoice cost.
- *Concrete Example*:
  - Original Sale Unit Cost = 80 SAR
  - Current Product Cost at Return Posting = 120 SAR
  - Returned Quantity = 10 units
  - Return Inventory & Accounting Valuation = $10 \times 120 = 1200 \text{ SAR}$.
