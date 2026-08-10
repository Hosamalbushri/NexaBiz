# ADR-005: Drift (SQLite) for Inventory Products

## Status

Accepted (implemented)

## Context

Inventory needs a **products catalog** with relational integrity (unique item codes / barcodes), indexed search, and room for future foreign keys (e.g. stock-count lines → products). Hive remains suitable for platform settings and the current stock-count item box, but is weak for relations and constraints.

## Decision

Use **Drift + SQLite** for inventory **products** master data:

- Module-owned database opened via `InventoryDatabase`
- Table `products` with unique `item_code`, optional unique `barcode`, required `pack_size` and `price`
- Access only through repositories / use cases — never from UI
- Products Excel import writes only to Drift (upsert by `item_code`)

Keep **Hive** for:

- Platform `app_settings`
- Stock-count `inventory_items` (unchanged in this phase)

Stock-count import and products import stay **separate**; no automatic sync.

## Alternatives Considered

- Hive box for products (rejected: weak constraints/relations)
- Isar / ObjectBox (rejected: prefer SQL relations + Drift codegen already aligned with Flutter ecosystem)
- Migrating stock-count items to Drift immediately (deferred)

## Consequences

- Dual local storage engines until stock count migrates
- Schema changes use Drift migrations (`schemaVersion` + `MigrationStrategy`)
- Join key for a future link remains `item_code` / `product.id`
