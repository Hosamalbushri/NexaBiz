# ADR-004: Local Database with Hive

## Status

Accepted (implemented) — **amended by [ADR-005](ADR-005-drift-products.md)**

## Context

Inventory counting must work offline with fast local reads/writes. A remote backend is not configured.

## Decision

Use **Hive** for:

- Platform settings box `app_settings`
- Inventory stock-count items box `inventory_items` owned by the Inventory module
- Typed adapter `InventoryItemAdapter` (`typeId: 0`)
- Access only through repositories/datasources — never from UI

Corrupt inventory boxes are recovered by delete-and-recreate in `InventoryHive.openBox()`.

Relational **products** master data uses **Drift / SQLite** — see ADR-005.

## Alternatives Considered

- SQLite / Drift for all local data (partially adopted later for products — ADR-005)
- Isar
- SharedPreferences for all data (insufficient for item collections)
- Remote-only storage (no network layer yet)

## Consequences

- Simple offline-first persistence for settings and stock-count rows
- Schema evolution needs care (no formal Hive migration framework yet)
- Module-owned boxes keep Core free of business schemas
- Dual engines until stock-count data is migrated to Drift
