# ADR-004: Local Database with Hive

## Status

Accepted (implemented)

## Context

Inventory counting must work offline with fast local reads/writes. A remote backend is not configured.

## Decision

Use **Hive** for local persistence:

- Platform settings box `app_settings`
- Inventory items box `inventory_items` owned by the Inventory module
- Typed adapter `InventoryItemAdapter` (`typeId: 0`)
- Access only through repositories/datasources — never from UI

Corrupt inventory boxes are recovered by delete-and-recreate in `InventoryHive.openBox()`.

## Alternatives Considered

- SQLite / Drift
- Isar
- SharedPreferences for all data (insufficient for item collections)
- Remote-only storage (no network layer yet)

## Consequences

- Simple offline-first persistence
- Schema evolution needs care (no formal migration framework yet)
- Module-owned boxes keep Core free of business schemas
